<script>
  import { AuthClient } from "@dfinity/auth-client";
  import { onMount } from "svelte";
  import { adminStatus, auth, createActor, tag } from "../store/auth";
  import { accountIdentifierFromBytes } from "../utils/helpers";

  /** @type {AuthClient} */
  let client;
  let url = window.location.href;

  // if (url.length < 121) {
  //   window.location.href = "https://gkox5-naaaa-aaaal-abhaq-cai.ic0.app/";
  // };

  let validation_id = url.slice(50,58);
  let access_code = url.slice(59,91);
  let loading = false;
  console.log("Validation ID: " + validation_id);
  console.log("Access Code: " + access_code);

  let message = "Please login.";

  onMount(async () => {
    client = await AuthClient.create();
    if (await client.isAuthenticated()) {
      loading = true;
      message = "Please wait...";
      handleAuth();
    }
  });

  function handleAuth() {
    auth.update(() => ({
      loggedIn: true,
      actor: createActor({
        agentOptions: {
          identity: client.getIdentity(),
        },
      })
    }));

    // isAdmin();
    validateAccess();
  };

  async function validateAccess() {
    console.log("Starting to validate access...");
    let validation_param = {
      validation: validation_id,
      access_code: access_code
    };

    let result = await $auth.actor.validateAccess(validation_param);
    console.log(result);
    if ( result.hasOwnProperty("Ok") ) {
      tag.update(() => ({
        valid: true,
        tag: result.Ok.tag,
        owner: result.Ok.owner,
        wallet: accountIdentifierFromBytes(result.Ok.wallet)
      }));
      message = "Access Granted!";
      setTimeout(() => {
        message = "";
      }, 5000)
      console.log("Completed validate access...");
    } else if ( result.hasOwnProperty("Err") ) {
      message = result.Err.msg;
    } else {
      message = "Something went wrong, your scan could not be validated."
    };
    loading = false;
  };

  async function isAdmin() {
    if ( await $auth.actor.isAdmin() ) {
      adminStatus.update(() => (true));
    };
  };

  function login() {
    loading = true;
    message = "Please wait...";
    client.login({
      identityProvider:
        process.env.DFX_NETWORK === "ic"
          ? "https://identity.ic0.app/#authorize"
          : `http://${process.env.INTERNET_IDENTITY_CANISTER_ID}.localhost:8000/#authorize`,
      onSuccess: handleAuth,
    });
  };

  async function logout() {
    await client.logout();

    auth.update(() => ({
      loggedIn: false,
      actor: createActor(),
      admin: false
    }));

    tag.update(() => ({
      valid: false,
      tag: "",
      owner: false,
      wallet: null
    }));

    message = "You've successfully logged out.";

    setTimeout(() => {
      window.location.href = "https://gkox5-naaaa-aaaal-abhaq-cai.ic0.app/";
    }, 3000)
  };
</script>

<div class="container">
  {#if !loading}
    {#if $auth.loggedIn}
      <div>
        <button on:click={logout}>Log out</button>
      </div>
    {:else}
      <button on:click={login}>Log in with Internet Identity</button>
    {/if}
  {/if}
  <h3>{#if loading}<div class="loader"></div>{/if}{" " + message}</h3>
</div>

<style>
  .container {
    /* margin: 30px 0 30px; */
    padding: 15px;
  }
</style>
