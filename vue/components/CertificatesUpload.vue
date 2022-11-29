<template>
  <div>
    <label>Import keys and certificates: </label>
    <a-upload action="/upload" :file-list="fileList" :remove="handleRemove" :before-upload="beforeUpload" :data="handleUploadParams" @change="handleChange">
      <a-button size="small" type="primary"><a-icon type="upload" /> Upload files</a-button>
    </a-upload>
  </div>
</template>

<script>
export default {
  data () {
    return {
      fileList: [],
      extensionsMap: { key: 'keys/', pem: 'keys/', csr: 'requests/', crt: 'certificates/' }
    }
  },
  methods: {
    handleRemove (file) {
      const index = this.fileList.indexOf(file)
      const newFileList = this.fileList.slice()
      newFileList.splice(index, 1)
      this.fileList = newFileList
    },
    beforeUpload (file) {
      const extension = file.name.split('.').at(-1)
      const isValid = Object.keys(this.extensionsMap).includes(extension)
      if (isValid) this.fileList = [...this.fileList, file]
      else this.$message.error('Invalid file type.')
    },
    handleUploadParams (file) {
      const extension = file.name.split('.').at(-1)
      const path = this.extensionsMap[extension]
      if (path) return { path: '/etc/ssl/' + path + file.name }
    },
    handleChange (state) {
      if (state.file.status === 'done') this.$emit('file-uploaded')
    }
  }
}
</script>
