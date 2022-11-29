<template>
  <div>
    <certificates-upload @file-uploaded="handleUpdate" />
    <div :key="tablesKey">
      <h2>Keys</h2>
      <certificates-table :path="paths.KEYS_PATH" />
      <h2>Certificates</h2>
      <certificates-table :path="paths.CERTS_PATH" />
      <h2>Certificate Signing Requests</h2>
      <certificates-table :path="paths.CSRS_PATH" />
    </div>
  </div>
</template>

<script>
import CertificatesUpload from './CertificatesUpload.vue'
import CertificatesTable from './CertificatesTable.vue'

export default {
  components: { CertificatesTable, CertificatesUpload },
  props: ['paths'],
  data () {
    return {
      tablesKey: 0
    }
  },
  methods: {
    handleUpdate () {
      this.tablesKey++
    }
  },
  created () {
  }
}
</script>
