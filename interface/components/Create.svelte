<script>
  import { daoActor, principal } from "../stores"
  import { get } from "svelte/store"
  import mot from "../assets/mot.png"

  let choosenproposal = "Input your proposal"
  let choosenmethod = "general"
  let limitvote = 1;
	let limitthreshold = 100;
  let p2
  let m2
  let lv2
  let lt2

  async function create_proposal(p3,m3,lv3,lt3) {
    let dao = get(daoActor)
    var obj = {};
    obj[m3] = null;
    let require = {method:  obj, limit_to_vote: [lv3], proposal_vote_threshold: [lt3]};
    if (!dao) {
      return
    }
    let res = await dao.submit_proposal(p3,require)
    if (res.Ok) {
      return res.Ok
    } else {
      throw new Error(res.Err)
    }
  }

  let promise = create_proposal(p2,m2,lv2,lt2)

  function handleCreateClick(p1,m1,lv1,lt1) {
    p2 = p1
    m2 = m1
    lv2 = lv1 * 100000000
    lt2 = lt1 * 100000000
    promise = create_proposal(p1,m1,lv2,lt2)
  }
  function onChange(event) {
		choosenmethod = event.currentTarget.value;
	}
</script>

<div class="votemain">
  {#if $principal}
    <img src={mot} class="bg" alt="logo" />
    <h1 class="slogan">Create a proposal</h1>
    <input
      bind:value={choosenproposal}
      placeholder="Input your proposal summary here"
    />
    <h1 class="slogan">Choose method</h1>
    <label>
      <input on:change={onChange} type="radio" name="amount" value="general" /> <p style="color:white">General</p>
    </label>
    <label>
      <input on:change={onChange} type="radio" name="amount" value="quadratic" /> <p style="color:white">Quadratic</p>
    </label>
    <h1 class="slogan">Limit MB token to vote</h1>
    <label>
      <input type=number bind:value={limitvote} min=1>
    </label>
    <h1 class="slogan">Limit threshold</h1>
    <label>
      <input type=number bind:value={limitthreshold} min=100>
    </label>
    <button on:click={handleCreateClick(choosenproposal,choosenmethod,limitvote,limitthreshold)}>Create!</button>
    {#await promise}
      <p style="color: white">...waiting</p>
    {:then proposal}
      <p style="color: white">Proposal created with payload {proposal}</p>
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
