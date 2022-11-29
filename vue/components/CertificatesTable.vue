<template>
  <div>
    <a-table :columns="columns" :data-source="files">
      <span slot="action" slot-scope="_, record">
        <a-button :disabled="!record.created" type="primary" @click="handleDownload(record)"><a-icon type="download" /></a-button>
        <a-popconfirm :title="`Delete ${record.name}?`" ok-text="Yes" cancel-text="No" @confirm="handleDelete(record)">
          <a-button type="danger"><a-icon type="delete" /></a-button>
        </a-popconfirm>
      </span>
      <span slot="status" slot-scope="_, record">
        {{ !!record.created ? "Created" : "Creating..." }}
      </span>
    </a-table>
    <form ref="download" method="POST" action="/download">
      <input v-show="false" type="text" :value="this.path + this.selectedFile" name="path"/>
      <input v-show="false" type="text" :value="this.selectedFile" name="filename"/>
    </form>
  </div>
</template>

<script>
export default {
  props: {
    path: String
  },
  data () {
    return {
      columns: [
        {
          key: 'key',
          dataIndex: 'key',
          title: '#',
          width: '5%'
        },
        {
          key: 'name',
          dataIndex: 'name',
          title: 'Name',
          width: '70%'
        },
        {
          key: 'status',
          dataIndex: 'status',
          title: 'Status',
          width: '30%',
          scopedSlots: { customRender: 'status' }
        },
        {
          key: 'action',
          dataIndex: 'action',
          title: 'Action',
          scopedSlots: { customRender: 'action' }
        }
      ],
      files: [],
      selectedFile: ''
    }
  },
  methods: {
    async getFiles () {
      const data = await this.$rpc.ubus('file', 'list', { path: this.path })
      if (!data) return
      this.files = data.entries.map((f, i) => {
        const ret = { key: i + 1, name: f.name, created: false }
        this.$rpc.ubus('file', 'read', { path: this.path + f.name }).then(c => { ret.created = !!(c && c.data) })
        return ret
      })
    },
    async handleDownload (f) {
      this.selectedFile = f.name
      await this.$nextTick()
      this.$refs.download.submit()
    },
    handleDelete (f) {
      this.$rpc.ubus('file', 'remove', { path: this.path + f.name })
      this.getFiles()
    },
    async checkFileCreated () {
      let stop = true
      for (const file of this.files) {
        const fileContents = await this.$rpc.ubus('file', 'read', { path: this.path + file.name })
        if (!fileContents) {
          stop = false
          file.created = false
        } else file.created = true
      }
      if (stop) this.$timer.stop('checkFileCreated')
    }
  },
  timers: {
    checkFileCreated: { time: 2000, autoStart: false, immediate: true, repeat: true }
  },
  async created () {
    await this.getFiles()
    this.$timer.start('checkFileCreated')
  }
}
</script>

<style scoped>
span {
  display: flex;
  gap: 0.5rem;
}
</style>
