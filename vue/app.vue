<template>
  <div>
    <a-tabs @change="handleChangeTab">
      <a-tab-pane :key="`form-${formKey}`" tab="Create certificates">
        <certificates-form :paths="paths" />
      </a-tab-pane>
      <a-tab-pane :key="`list-${listKey}`" tab="View certificates">
        <certificates-list :paths="paths" />
      </a-tab-pane>
    </a-tabs>
  </div>
</template>

<script>
import CertificatesForm from './components/CertificatesForm.vue'
import CertificatesList from './components/CertificatesList.vue'

const ROOT_PATH = '/etc/ssl/'

export default {
  components: { CertificatesForm, CertificatesList },
  data () {
    return {
      paths: {
        KEYS_PATH: ROOT_PATH + 'keys/',
        CSRS_PATH: ROOT_PATH + 'requests/',
        CERTS_PATH: ROOT_PATH + 'certificates/'
      },
      formKey: 0,
      listKey: 0
    }
  },
  methods: {
    handleChangeTab (activeKey) {
      // Refresh tab on leave
      if (activeKey === `form-${this.formKey}`) this.listKey++
      if (activeKey === `list-${this.formKey}`) this.formKey++
    }
  }
}
</script>

<style scoped>
h2 {
  margin-left: 1rem;
}
</style>
