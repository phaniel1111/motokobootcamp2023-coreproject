<script>
  export let post
</script>

<div class="post-preview">
  <h2>{post[0]}</h2>
  <p>From: {post[1].proposer.toString()}</p>
  <p>Change website text to: {post[1].payload}</p>
  <p>Limit to vote: {(post[1].limit_to_vote /  BigInt(100000000)).toString()}</p>
  <p>Limit to vote threshold: {(post[1].proposal_vote_threshold  / BigInt(100000000)).toString()}</p>
  <p>Vote method: {Object.keys(post[1].method)}</p>
  <p>
    Yes: {(post[1].votes_yes.amount_e8s / BigInt(100000000)).toString()}, No: {(
      post[1].votes_no.amount_e8s / BigInt(100000000)
    ).toString()}
  </p>
  <p>State: {Object.keys(post[1].state)}</p>
</div>

<style>
  .post-preview {
    border: 1px solid white;
    border-radius: 10px;
    margin-bottom: 2vmin;
    padding: 2vmin;
  }
  h2 {
    color: white;
  }

  p {
    color: white;
  }
</style>