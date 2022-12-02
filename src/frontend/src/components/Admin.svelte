<script>
  import { auth } from "../store/auth";

  let uid;
  let key = "nothing yet";
  let transferCode = "nothing yet";
  let CMACs = "paste here";
  let ctr = "000000";
  let cmac = "0";
  let scanResult;

  async function register(rawUid) {
    let uid = parseInt(rawUid, 16);
    let result = await $auth.actor.registerTag(uid);
    key = result.key;
    transferCode = result.transfer_code;
  };

  async function upload(CMACs, rawUid) {
    let uid = parseInt(rawUid, 16);
    let data = CMACs.split(",");
    await $auth.actor.importScans(uid, data);
  };

  async function scan(rawUid, rawCtr, cmac) {
    let uid = parseInt(rawUid, 16);
    let ctr = parseInt(rawCtr, 16);
    scanResult = await $auth.actor.scan(uid, ctr, cmac);
  };

  async function initialize() {
    await $auth.actor.initializeNtagle();
  };
</script>

<h1>Admin Functions</h1>
<button on:click={initialize}>Initialize</button>