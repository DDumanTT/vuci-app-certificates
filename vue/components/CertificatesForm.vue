<template>
  <a-form-model ref="form" :model="form" :rules="rules" :labelCol="{ span: 6 }" :wrapperCol="{ span: 14 }" >
    <a-form-model-item label="Type">
      <a-select v-model="form.type" @change="$refs.form.clearValidate()">
        <a-select-option value="client">
          Client
        </a-select-option>
        <a-select-option value="server">
          Server
        </a-select-option>
        <a-select-option value="ca">
          CA
        </a-select-option>
        <a-select-option value="dh">
          Diffie-Hellman
        </a-select-option>
      </a-select>
    </a-form-model-item>
    <a-form-model-item label="File name" prop="fileName">
      <a-input v-model="form.fileName" required />
    </a-form-model-item>
    <a-form-model-item v-if="form.type !== 'dh'" label="Common Name (e.g. server FQDN or YOUR name)" prop="certFields.name" >
      <a-input v-model="form.certFields.name" required />
    </a-form-model-item>
    <a-form-model-item v-if="form.type === 'client' || form.type === 'server'" label="Certificate Authority" prop="selectedCA">
      <a-select v-model="form.selectedCA">
        <a-select-option value="" disabled>
          Select a CA
        </a-select-option>
        <a-select-option v-for="file in caList" :key="file.id" :value="file.name">
          {{ file.name }}
        </a-select-option>
      </a-select>
    </a-form-model-item>
    <template v-if="form.type !== 'dh'">
      <a-form-model-item label="Save certificate signing request">
        <a-switch v-model="form.saveCsr" />
      </a-form-model-item>
      <a-form-model-item label="Include subject information">
        <a-switch v-model="form.showCertFields" />
      </a-form-model-item>
      <div v-if="form.showCertFields">
        <a-form-model-item label="Country Name (2 letter code)" prop="certFields.country" >
          <a-input v-model="form.certFields.country" />
        </a-form-model-item>
        <a-form-model-item label="State or Province Name" prop="certFields.province" >
          <a-input v-model="form.certFields.province" />
        </a-form-model-item>
        <a-form-model-item label="Locality Name (eg, city)" prop="certFields.city" >
          <a-input v-model="form.certFields.city" />
        </a-form-model-item>
        <a-form-model-item label="Organization Name (eg, company)" prop="certFields.org" >
          <a-input v-model="form.certFields.org" />
        </a-form-model-item>
        <a-form-model-item label="Organizational Unit Name (eg, section)" prop="certFields.orgUnit" >
          <a-input v-model="form.certFields.orgUnit" />
        </a-form-model-item>
        <a-form-model-item label="Email Address" prop="certFields.email">
          <a-input v-model="form.certFields.email" />
        </a-form-model-item>
      </div>
    </template>
    <a-form-model-item v-else label="Bits" prop="bits">
      <a-input v-model="form.bits" placeholder="1024" />
    </a-form-model-item>
    <a-form-model-item :wrapper-col="{ span: 14, offset: 6 }">
      <a-button type="primary" @click="onSubmit" :loading="creatingCert">
        Create
      </a-button>
    </a-form-model-item>
  </a-form-model>
</template>

<script>
export default {
  props: ['paths'],
  data () {
    return {
      creatingCert: false,
      caList: [],
      form: {
        type: 'client',
        fileName: '',
        selectedCA: '',
        bits: undefined,
        showCertFields: false,
        saveCsr: false,
        certFields: {
          name: '',
          country: '',
          province: '',
          city: '',
          org: '',
          orgUnit: '',
          email: ''
        }
      },
      rules: {
        fileName: [
          { required: true, message: 'Certificate file name is required', trigger: 'blur' }
        ],
        selectedCA: [{ required: true, message: 'Certificate Authority has to be selected (create a new one if none exist)', trigger: 'blur' }],
        'certFields.name': [{ required: true, message: 'Common name (e.g. server FQDN or YOUR name) is required', trigger: 'blur' }],
        'certFields.country': [{ len: 2, message: 'Country name has to be a 2 letter code.', trigger: 'blur' }],
        'certFields.email': [{ type: 'email', message: 'Email is invalid', trigger: 'blur' }]
      }
    }
  },
  methods: {
    onSubmit () {
      this.$refs.form.validate(async valid => {
        if (!valid) return
        this.creatingCert = true
        if (this.form.type === 'client') {
          this.callWithFeedback(() => this.$rpc.call('certificates', 'createCert', this.form),
            'Creating client certificate', 'Created client certificate', 'Failed to create client certificate')
        } else if (this.form.type === 'server') {
          this.callWithFeedback(() => this.$rpc.call('certificates', 'createCert', this.form),
            'Creating server certificate', 'Created server certificate', 'Failed to create server certificate')
        } else if (this.form.type === 'ca') {
          await this.callWithFeedback(() => this.$rpc.call('certificates', 'createCert', this.form),
            'Creating Certificate Authority', 'Created Certificate Authority', 'Failed to create Certificate Authority')
          this.getCAs()
        } else if (this.form.type === 'dh') {
          this.callWithFeedback(() => this.$rpc.call('certificates', 'createDH', this.form),
            'Creating Diffie-Hellman parameters (this will take a while)', undefined, 'Failed to create Diffie-Hellman parameters')
        } else {
          this.$message.error('Invalid certificate type')
        }
      })
    },
    async callWithFeedback (call, loading, success, error) {
      loading && this.$message.loading(loading)
      try {
        await call()
      } catch (e) {
        error && this.$message.error(`${error} (${JSON.parse(e).error.message})`)
        this.creatingCert = false
        return
      }
      success && this.$message.success(success)
      this.$refs.form.resetFields()
      this.creatingCert = false
    },
    async getCAs () {
      this.caList = []
      const files = (await this.$rpc.ubus('file', 'list', { path: this.paths.CERTS_PATH }))
      files && files.entries.forEach((f, i) => {
        const parts = f.name.split('.')
        const name = parts[0]
        const ext = parts.slice(-1)[0]
        if (ext === 'crt') this.caList.push({ id: i, name })
      })
      this.caList.sort()
    }
  },
  created () {
    this.getCAs()
  }
}
</script>
