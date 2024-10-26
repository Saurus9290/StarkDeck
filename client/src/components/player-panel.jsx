import Player from './player'
import StyledButton from './styled-button'
import { useState, useEffect } from 'react'
import { Provider, Contract, Account, ec, json } from 'starknet';
import { RpcProvider } from 'starknet';

export default function PlayerPanel() {
  const [gameSize, setGameSize] = useState(2);

  const showPK = false

  return (
    <div className='relative'>
      {gameSize == 2 && (
        <>
          <Player1 />
          <Player showPK={showPK} name='Player 2' point={100} avatar={3} style={{ left: 80, top: 120 }} />
        </>
      )}
      {gameSize == 3 && (
        <>
          <Player1 />
          <Player showPK={showPK} name='Player 2' point={100} avatar={3} style={{ left: 80, top: 120 }} />
          <Player showPK={showPK} name='Player 3' point={100} style={{ right: 300, top: 120 }} rightSide />
        </>
      )}
      {gameSize == 4 && (
        <>
          <Player1 />
          <Player showPK={showPK} name='Player 2' point={100} avatar={3} style={{ left: 80, top: 120 }} />
          <Player showPK={showPK} name='Player 3' point={100} style={{ right: 300, top: 120 }} rightSide />
          <Player showPK={showPK} name='Player 4' point={100} avatar={5} style={{ left: 80, top: 300 }} />
        </>
      )}
      {gameSize == 4 && (
        <>
          <Player1 />
          <Player showPK={showPK} name='Player 2' point={100} avatar={3} style={{ left: 80, top: 120 }} />
          <Player showPK={showPK} name='Player 3' point={100} style={{ right: 300, top: 120 }} rightSide />
          <Player showPK={showPK} name='Player 4' point={100} avatar={5} style={{ left: 80, top: 300 }} />
          <Player showPK={showPK} name='Player 5' point={100} avatar={7} style={{ right: 300, top: 300 }} rightSide />
        </>
      )}
    </div>

  )
}

function Player1() {

  const x = 360, y = 470
  const [abi, setAbi] = useState(null)
  const [contract, setContract] = useState(null)

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
  }, [abi, contract])

  const shuffleDeck = async () => {
    contract.connect(account0);

    const transferCall = contract.populate('shuffle_deck');
    const { transaction_hash: transferTxHash } = await account0.execute(transferCall);
    // Wait for the invoke transaction to be accepted on Starknet
    console.log(`Waiting for Tx to be Accepted on Starknet - Transfer...`);
    await provider.waitForTransaction(transferTxHash);

    toast({
      title: "Success 🎉",
      description: `card has been shuffled successfully`,
    })
  }

  return (
    <Player
      x={x} y={y}
      style={{ left: x, top: y }}
      isCurrentPlayer={true}
    >
      {
        <div className='relative px-6 py-1 text-center'>
          <StyledButton className='bg-[rgb(1,145,186)]' roundedStyle='rounded-full' onClick={() => shuffleDeck()}>SHUFFLE</StyledButton>
        </div>
      }
    </Player>
  )
}