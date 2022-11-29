local rpc = require "vuci.rpc"
local openssl = require('openssl')

local ROOT_PATH = "/etc/ssl/"

local KEYS_PATH = ROOT_PATH .. "keys/"
local CSRS_PATH = ROOT_PATH .. "requests/"
local CERTS_PATH = ROOT_PATH .. "certificates/"

os.execute('mkdir -p ' .. KEYS_PATH)
os.execute('mkdir -p ' .. CSRS_PATH)
os.execute('mkdir -p ' .. CERTS_PATH)

local CAExts = {
    {
        object='basicConstraints',
        value='CA:true',
        critical = true
    },
    {
        object='keyUsage',
        value='keyCertSign'
    }
}

local M = {}

function M.createCert (params)
    if (not params) then return rpc.ERROR_CODE_INVALID_PARAMS end

    local fileName = params.fileName
    local certFields = params.certFields

    local pkey = openssl.pkey.new()

    writeFile(KEYS_PATH, fileName .. '.key', pkey:export())
    
    local subject = createSubject(certFields)
    if (not subject) then return rpc.ERROR_CODE_INVALID_PARAMS end
    local csr = openssl.x509.req.new(subject, pkey)
    if (params.saveCsr) then
        writeFile(CSRS_PATH, fileName .. '.csr', csr:export())
    end
    local cert = openssl.x509.new(csr)
    cert:notbefore(os.time())
    cert:notafter(os.time() + 3600 * 24 * 365)

    if (params.selectedCA and params.selectedCA ~= "") then
        -- Sign against a CA
        -- Read CA private key
        local file = io.open(KEYS_PATH .. params.selectedCA .. '.key', "r")
        if (not file) then return rpc.ERROR_CODE_INTERNAL_ERROR end
        local CAKey = openssl.pkey.read(file:read("*a"), true)

        -- Read CA certificate
        local file = io.open(CERTS_PATH .. params.selectedCA .. '.crt', "r")
        if (not file) then return rpc.ERROR_CODE_INTERNAL_ERROR end
        local CACert = openssl.x509.read(file:read("*a"))

        local certType = nil
        if (params.type == 'client') then certType = 'clientAuth' end
        if (params.type == 'server') then certType = 'serverAuth' end

        cert:extensions(to_extensions({
            {
                object = 'basicConstraints',
                value = 'CA:false'
            },
            {
                object = 'extendedKeyUsage',
                value = certType
            }
        }))
        cert:sign(CAKey, CACert)
    else
        -- Self sign CA
        cert:extensions(to_extensions(CAExts))
        cert:sign(pkey, cert)
    end
    
    writeFile(CERTS_PATH, fileName .. '.crt', cert:export())

    return {
        key = { path = KEYS_PATH, fileName = fileName .. '.key' },
        csr = params.saveCsr and { path = KEYS_PATH, fileName = fileName .. '.csr' },
        cert = { path = CERTS_PATH, fileName = fileName .. '.crt'}
    }
end

function M.createDH(params)
    if (not params) then return rpc.ERROR_CODE_INVALID_PARAMS end

    local fileName = params.fileName
    local bits = params.bits or 1024

    io.popen('openssl dhparam -out ' .. KEYS_PATH .. fileName .. '.pem ' .. bits)

    return { path = KEYS_PATH, fileName = fileName .. '.pem' }
end

function createSubject (data)
    local subjectKeysMap = {
        email = 'emailAddress',
        country = 'C',
        province = 'ST',
        city = 'L',
        org = 'O',
        orgUnit = 'OU',
        name = 'CN'
    }

    local out = {}
    for key, value in pairs(data) do
        if (value and value ~= '') then
            table.insert(out, { [subjectKeysMap[key]] = value })
        end
    end

    return openssl.x509.name.new(out)
end

function to_extensions(exts)
    exts = exts
    local ret = {}
    for i=1, #exts do
        ret[i] = openssl.x509.extension.new_extension(exts[i])
    end
    return ret
end

function writeFile(path, fileName, content)
    os.execute('mkdir -p ' .. path)
    local handle = io.open(path .. fileName, "w")
    if (not handle) then return rpc.ERROR_CODE_INTERNAL_ERROR end
    handle:write(content)
    handle:close()
end

return M
