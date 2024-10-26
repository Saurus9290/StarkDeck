'use client'

import StyledButton from '@/components/styled-button'
import { useRef, useEffect, useState } from 'react'
import Link from 'next/link';
import {
    Dialog,
    DialogContent,
    DialogTrigger,
} from "@/components/ui/dialog"
import { checkAddress, getUserData } from '@/util/databaseFunctions';
import { useRouter } from 'next/navigation';
import { useDynamicContext } from '@dynamic-labs/sdk-react-core';
import { DynamicWidget } from '@dynamic-labs/sdk-react-core';
import TokenInfoBar from '@/components/TokenBar'
import { Provider, Contract, Account, ec, json } from 'starknet';
import { RpcProvider } from 'starknet';

export default function JoinGame() {

    const [walletConnected, setWalletConnected] = useState(false);
    const [gameId, setGameId] = useState("")
    const [accounts, setAccounts] = useState(null);
    const [profile, setProfile] = useState(false);
    const [open, setOpen] = useState(false);
    const [loading, setLoading] = useState(false)
    const [joining, setJoining] = useState(false)
    const [abi, setAbi] = useState(null)
    const [contract, setContract] = useState(null)

    const router = useRouter()

    const { user } = useDynamicContext();

    const provider = new RpcProvider({
        nodeUrl: 'https://free-rpc.nethermind.io/sepolia-juno/v0_7',
    });

    const pokerContractAddress = '0x02ce5351ec57e3c183799fcd70bb0dea15ff19b6c034f9e2b1ad045f3c199b90';
    const tokenAddress = '0x04ab2280bd66aa4d6195106662308e48b6ac2ab011fcf712e3f5d223f15c43e2';

    const account = new Account(provider, '0x02a72374D267e09055Be18013DFf9384a2887d7e47dACb08A6eDDa15EA5470F2', process.env.NEXT_PUBLIC_PRIVATE_KEY)

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
            const gameContract = new Contract(abi, pokerContractAddress, provider)
            setContract(gameContract)
            gameContract.connect(account);
        }
    }, [abi])

    const joinGame = async () => {
        if (user) {
            setJoining(true)
            contract.connect(account);
            const { abi: tokenAbi } = await provider.getClassAt(tokenAddress);
            const tokenContract = new Contract(tokenAbi, tokenAddress, provider)
            tokenContract.connect(account);

            const approveCall = tokenContract.populate('approve', {
                spender: pokerContractAddress,
                amount: 1n * 10n ** 18n,
            });

            const { transaction_hash: approvetransferTxHash } = await account.execute(approveCall);
            // Wait for the invoke transaction to be accepted on Starknet
            console.log(`Waiting for Tx to be Accepted on Starknet - joining..., hash: ${approvetransferTxHash}`);
            await provider.waitForTransaction(approvetransferTxHash);

            const call = contract.populate('join_game', {
                amount: 1n * 10n ** 18n,
            });

            const { transaction_hash: transferTxHash } = await account.execute(call);
            // Wait for the invoke transaction to be accepted on Starknet
            console.log(`Waiting for Tx to be Accepted on Starknet - joining..., hash: ${transferTxHash}`);
            await provider.waitForTransaction(transferTxHash);

            toast({
                title: "Success 🎉",
                description: `successfully joined the games`,
            })

            router.push(`/game`);

            setJoining(false)
        } else {
            alert("Please connect your wallet")
        }
    }

    const checkUserData = async () => {
        try {
            let data = { id: "", address: "", name: "", userName: "", status: "" };

            if (userData == data) {
                setOpen(true)
            }
            if (user?.verifiedCredentials[0].address) {
                setWalletConnected(true)
                setLoading(true)
                checkAddress(user.verifiedCredentials[0].address).then((res) => {
                    console.log("res:", res);
                    setLoading(false)
                    if (res) {
                        setProfile(true)
                    }
                })
                data = await getUserData(user.verifiedCredentials[0].address)
            }

            console.log("data", data.response[0])

        } catch (error) {
            console.log(error.message, error.code)
        }
    }

    const openHandler = () => {
        setOpen(false)
    }

    return (
        <div className='relative'>
            <TokenInfoBar />
            <div className='bg-white w-full max-w-[1280px] h-[720px] overflow-hidden mx-auto my-8 px-4 py-2 rounded-lg bg-cover bg-[url("/bg-2.jpg")] relative shadow-[0_0_20px_rgba(0,0,0,0.8)]'>
                {/* <div className='absolute top-5 left-5 w-40 h-40 bg-no-repeat bg-[url("/logo.png")]'></div> */}
                <div className='absolute inset-0 bg-no-repeat bg-[url("/table-1.png")]'></div>
                <div className='absolute left-8 -right-8 top-14 -bottom-14 bg-no-repeat bg-[url("/dealer.png")] transform-gpu'>
                    <div className='absolute -left-8 right-8 -top-14 bottom-14 bg-no-repeat bg-[url("/card-0.png")] animate-pulse'></div>
                </div>
                <div className='absolute top-0 left-1/2 right-0 bottom-0 pr-20 py-12'>
                    <div className='relative text-center flex justify-center'>
                        <img src='/login-button-bg.png' />
                        <div className='left-1/2 -translate-x-1/2 absolute bottom-4'>
                            <DynamicWidget innerButtonComponent={
                                <StyledButton data-testid="connect" roundedStyle='rounded-full' className='bg-[#ff9000] text-2xl'>{accounts ? `Connected Wallet` : `Connect Wallet`}</StyledButton>
                            } />
                        </div>
                    </div>
                    {user?.verifiedCredentials[0].address &&
                        <div className='flex flex-col items-center'>
                            {/* <input onChange={(e) => setGameId(e.target.value)} className='w-full border-2 mt-3 border-[#00b69a] bg-gray-600/60 rounded-md p-5 py-2 text-white' placeholder='enter the code' /> */}
                            <StyledButton className='w-full bg-[#00b69a] bottom-4 text-2xl mt-3' onClick={() => joinGame()}>{joining ? `Joining Game...` : `Enter Game`} </StyledButton>
                        </div>
                    }
                </div>
            </div>
        </div>
    )
}