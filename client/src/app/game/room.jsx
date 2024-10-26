'use client'
import PlayerPanel from '@/components/player-panel'
import { useState, useEffect } from 'react'
import { Provider, Contract, Account, ec, json } from 'starknet';
import { RpcProvider } from 'starknet';
import { useDynamicContext } from '@dynamic-labs/sdk-react-core';

export default function GameRoom() {

  const [loading, setLoading] = useState(true);
  const [abi, setAbi] = useState(null)
  const [contract, setContract] = useState(null)
  const [players, setPlayers] = useState([])

  const { user } = useDynamicContext();

  const provider = new RpcProvider({
    nodeUrl: 'https://free-rpc.nethermind.io/sepolia-juno/v0_7',
  });

  const pokerContractAddress = '0x02ce5351ec57e3c183799fcd70bb0dea15ff19b6c034f9e2b1ad045f3c199b90';

  const account0 = new Account(provider, '0x02a72374D267e09055Be18013DFf9384a2887d7e47dACb08A6eDDa15EA5470F2', process.env.NEXT_PUBLIC_PRIVATE_KEY)

  useEffect(() => {
    const fetchData = async () => {
      const { abi: testAbi } = await provider.getClassAt(pokerContractAddress);
      setAbi(testAbi)
    }
    fetchData()
  }, [pokerContractAddress])

  useEffect(() => {
    if (!abi) return;
    if (!contract) {
      const pokerContract = new Contract(abi, pokerContractAddress, provider)
      setContract(pokerContract)
      pokerContract.connect(account0);
    }

    if (contract && user?.verifiedCredentials[0].address) {
      const findPlayers = async () => {
        const players = await contract.get_player(user?.verifiedCredentials[0].address);
        setPlayers((prev) => [...prev, players])
      }

      findPlayers()
    }
  }, [abi, contract])
  
  return (
    <>
      <div className='hidden scale-[0.975]'></div>
      <div className='transition-transform relative w-full max-w-[1280px] h-[720px] m-20 mt-10 mx-auto bg-[url("/bg-3.jpg")] select-none rounded-3xl overflow-hidden shadow-[0_0_20px_rgba(0,0,0,0.8)]'
        onTransitionEnd={e => {
          e.target.classList.remove('scale-[0.975]')
        }}
      >
        <PlayerPanel></PlayerPanel>
      </div>
    </>
  )
}