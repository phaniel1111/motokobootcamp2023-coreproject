import { principal } from "../stores"
import { daoActor } from "../stores"
import { tokenActor } from "../stores"
import { idlFactory as idlFactoryToken } from "../dao.did.js"
import { idlFactory as idlFactoryDAO } from "../../src/declarations/dao/dao.did.js"

//TODO : Add your mainnet id whenever you have deployed on the IC
const daoCanisterId = "no4gy-cqaaa-aaaag-abc4q-cai"
const tokenCanisterId = "db3eq-6iaaa-aaaah-abz6a-cai"
// See https://docs.plugwallet.ooo/ for more informations
// This code is not clean but does the job
// The documentation recommends to use the official methods to create the agent and not rely on the libraries from dfinity
// But: local dev is broken if I use the official methods...
export async function plugConnection() {
  const result = await window.ic.plug.requestConnect({
    whitelist: [daoCanisterId,tokenCanisterId],
  })

  const p = window.ic.plug.agent.getPrincipal()
  const DAOactor = await window.ic.plug.createActor({
    canisterId: daoCanisterId,
    interfaceFactory: idlFactoryDAO,
  })
  const Tokenactor = await window.ic.plug.createActor({
    canisterId: tokenCanisterId,
    interfaceFactory: idlFactoryToken,
  })

  principal.update(() => p)
  daoActor.update(() => DAOactor)
  tokenActor.update(() => Tokenactor)
}