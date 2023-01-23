<script>
    import { tokenActor, daoActor, principal } from "../stores"
    import { get } from "svelte/store"
    import mot from "../assets/mot.png"
    import { Principal as Princ} from "@dfinity/principal";

    let amount = 1;
    let days = 1;
 
    let lv2
    let lt2
  
    async function create_neuron(lv3,lt3) {
      let dao = get(daoActor)
      let token = get(tokenActor)

      if (!dao) return
      if (!token) return
      let para = {
        to : {
            owner: Princ.fromText("no4gy-cqaaa-aaaag-abc4q-cai"),
            subaccount: [],
        },
        fee: 1000000,
        memo: [],
        from_subaccount:[],
        created_at_time: [],
        amount:lv3,
      }
      console.log("Transfer parameters: ", para);
      let rs = await token.icrc1_transfer(para);
      let res = await dao.create_neuron(rs,lt3)
      if (res.Ok) {
        return res.Ok
      } else {
        throw new Error(res.Err)
      }
    }
  
    let promise = create_neuron(lv2,lt2)
  
    function handleCreateClick(lv1,lt1) {
      lv2 = lv1 * 100000000
      lt2 = lt1 * 86400000000000
      promise = create_neuron(lv2,lt2)
    }

  </script>
  <div class="votemain">
    {#if $principal}
      <img src={mot} class="bg" alt="logo" />
      <h1 class="slogan">Amount to lock</h1>
      <label>
        <input type=number bind:value={amount} min=1>
      </label>
      <h1 class="slogan">Days to lock</h1>
      <label>
        <input type=number bind:value={days} min=1>
      </label>
      <button on:click={handleCreateClick(amount,days)}>Create!</button>
      {#await promise}
        <p style="color: white">...waiting</p>
      {:then proposal}
        <p style="color: white">Neuron created</p>
      {:catch error}
        <p style="color: red">{error.message}</p>
      {/await}
    {:else}
      <p class="example-disabled">Connect with a wallet to access this example</p>
    {/if}
  </div>
  
  <style>
    input {
      width: 100%;
      padding: 12px 20px;
      margin: 8px 0;
      display: inline-block;
      border: 1px solid #ccc;
      border-radius: 4px;
      box-sizing: border-box;
    }
  
    .bg {
      height: 55vmin;
      animation: pulse 3s infinite;
    }
  
    .votemain {
      display: flex;
      flex-direction: column;
      justify-content: center;
    }
  
    button {
      background-color: #4caf50;
      border: none;
      color: white;
      padding: 15px 32px;
      text-align: center;
      text-decoration: none;
      display: inline-block;
      font-size: 16px;
      margin: 4px 2px;
      cursor: pointer;
    }
  </style>
  