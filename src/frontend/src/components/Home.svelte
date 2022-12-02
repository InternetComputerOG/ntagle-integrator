<script>
  import { onMount } from "svelte";
  import { auth, scanCredentials, createActor, tag } from "../store/auth";
  import QRCode from "./QRJS.svelte";

  let template_url = "https://gkox5-naaaa-aaaal-abhaq-cai.ic0.app/tag?m=00000000000000x000000x0000000000000000x00000000000000000000000000000000";
  let errorMsg = "";
  let errorMsgTag1 = "";
  let errorMsgTag2 = "";

  let tag1Uid = "046C2152E11190";
  let tag1Status = true;
  let tag1OwnerPrincipal = "Something went wrong...";
  let tag1Balance = "Something went wrong...";
  let tag1Url = "";
  let tag1Count = 0;

  let tag2Uid = "044A2152E11190";
  let tag2Status = true;
  let tag2OwnerPrincipal = "Something went wrong...";
  let tag2Balance = "Something went wrong...";
  let tag2Url = "";
  let tag2Count = 0;

  let pendingTagData = true;

  let tag1Scanning = false;
  let tag1Scanned = false;
  let didCopyTag1Url = false;

  let tag2Scanning = false;
  let tag2Scanned = false;
  let didCopyTag2Url = false;

  onMount(async () => {
    refreshTagData();
  });

  async function writeTemplate() {
    try {
      const ndef = new NDEFReader();
      await ndef.write({
        records: [{ recordType: "url", data: template_url }]
      });
    } catch (error) {
      console.log(error);
    }
  };

  async function refreshTagData() {
    console.log("Refreshing Demo Tag Data.");
    pendingTagData = true;
    tag1Scanned = false;
    tag2Scanned = false;

    auth.update(() => ({
      loggedIn: false,
      actor: createActor(),
      admin: false
    }));

    scanCredentials.update(() => ({
      uid: 0,
      ctr: 0,
      cmac: "",
      transfer_code: ""
    }));

    tag.update(() => ({
      valid: false,
      owner: false,
      locked: true,
      transfer_code: null,
      wallet: null
    }));

    let result = await $auth.actor.demoTagData();
    console.log(result);

    if(result.hasOwnProperty("Ok")) {
      tag1Status = result.Ok.tag1.locked;
      tag1OwnerPrincipal = result.Ok.tag1.owner;
      tag1Balance = (Number(result.Ok.tag1.balance) / 100000000).toFixed(2);

      tag2Status = result.Ok.tag2.locked;
      tag2OwnerPrincipal = result.Ok.tag2.owner;
      tag2Balance = (Number(result.Ok.tag2.balance) / 100000000).toFixed(2);
    } else {
      errorMsg = result.Err.msg;
    };

    pendingTagData = false;
  };

  async function tagScan(tag) {
    tag1Scanned = false;
    tag2Scanned = false;

    if (tag == 1) {
      tag1Scanning = true;
      let result = await $auth.actor.demoTagGenerateScan(tag);

      if(result.hasOwnProperty("Ok")) {
        tag1Count = result.Ok.count + 1;
        let count = ("000000" + (Number(result.Ok.count) + 1).toString(16)).slice(-6);
        tag1Url = "https://gkox5-naaaa-aaaal-abhaq-cai.ic0.app/tag?m=" + tag1Uid + "x" + count + "x" + result.Ok.cmac + "x" + result.Ok.transfer_code;
      } else {
        errorMsgTag1 = result.Err.msg;
      };

      tag1Scanning = false;
      tag1Scanned = true;
    } else {
      tag2Scanning = true;
      let result = await $auth.actor.demoTagGenerateScan(tag);

      if(result.hasOwnProperty("Ok")) {
        tag2Count = result.Ok.count + 1;
        let count = ("000000" + (Number(result.Ok.count) + 1).toString(16)).slice(-6);
        tag2Url = "https://gkox5-naaaa-aaaal-abhaq-cai.ic0.app/tag?m=" + tag2Uid + "x" + count + "x" + result.Ok.cmac + "x" + result.Ok.transfer_code;
      } else {
        errorMsgTag2 = result.Err.msg;
      };

      tag2Scanning = false;
      tag2Scanned = true;
    };
  };

  function copyTag1Url(text) {
    if(window.isSecureContext) {
      didCopyTag1Url = true;
      navigator.clipboard.writeText(text);
    }
    setTimeout(() => {
      didCopyTag1Url = false;
    }, 3000)
  };

  function copyTag2Url(text) {
    if(window.isSecureContext) {
      didCopyTag2Url = true;
      navigator.clipboard.writeText(text);
    }
    setTimeout(() => {
      didCopyTag2Url = false;
    }, 3000)
  };

</script>

<h1>Welcome</h1>
<!-- <button on:click={async () => await writeTemplate()}>Write Template</button> -->
<p>This is a demo of an integration!</p>
<style>
  .container {
    margin: 30px 0;
    padding: 15px;
    border: 2px solid #fff;
    background-color: rgb(27, 27, 27);
    text-align: left;
  }

  .qr_code {
    padding: 5px;
    background-color: white;
    display: inline-block;
  }

  button {
    margin-left: 0px;
  }

  .label {
    color: rgb(111, 111, 111);
  }

  .container h4, h6 {
    margin: 3px;
  }

  h1 {
    margin-top: 60px;
  }

</style>