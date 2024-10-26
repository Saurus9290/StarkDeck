import FrameBox from './frame-box'
import StyledButton from './styled-button'
import { useRouter } from 'next/navigation'
import { useState, useEffect } from 'react'
import { RxCross2 } from "react-icons/rx";
import {
    Dialog,
    DialogContent,
    DialogTrigger,
    DialogDescription,
    DialogHeader,
    DialogTitle,
} from "@/components/ui/dialog"
import { Provider, Contract, Account, ec, json } from 'starknet';
import { RpcProvider } from 'starknet';
import { useDynamicContext } from '@dynamic-labs/sdk-react-core';
import { useToast } from "@/components/ui/use-toast"

// ShareLink component - used for sharing a match link
export default function AddFundPopUp({ openHandler, balance, setBalance }) {
    const router = useRouter()
    const [amount, setAmount] = useState(0)
    const [abi, setAbi] = useState(null)
    const [contract, setContract] = useState(null)

    const { toast } = useToast()

    const { user } = useDynamicContext();

    const provider = new RpcProvider({
        nodeUrl: 'https://free-rpc.nethermind.io/sepolia-juno/v0_7',
    });

    const tokenAddress = '0x04ab2280bd66aa4d6195106662308e48b6ac2ab011fcf712e3f5d223f15c43e2';

    const account0 = new Account(provider, '0x02a72374D267e09055Be18013DFf9384a2887d7e47dACb08A6eDDa15EA5470F2', process.env.NEXT_PUBLIC_PRIVATE_KEY)

    useEffect(() => {
        const fetchData = async () => {
            const { abi: testAbi } = await provider.getClassAt(tokenAddress);
            setAbi(testAbi)
        }
        fetchData()
    }, [tokenAddress])

    useEffect(() => {
        if (!abi) return;
        if (!contract) {
            const tokenContract = new Contract(abi, tokenAddress, provider)
            setContract(tokenContract)
            tokenContract.connect(account0);
        }

        if (contract) {
            const findBalance = async () => {
                const balanceInitial = await contract.balanceOf(account0.address);
                console.log('account0 has a balance of:', balanceInitial);
            }

            findBalance()
        }
    }, [abi, contract])

    const handleClick = (event) => {
        const value = parseInt(event.target.getAttribute('data-value'));
        const total = amount + value;
        console.log(total)
        setAmount(total)
    };

    const ISSERVER = typeof window === "undefined";

    const [tokenAmount, setTokenAmount] = useState(0);

    useEffect(() => {
        if (!ISSERVER) {
            // Retrieve game data from local storage
            const storedUserData = localStorage.getItem('amount');

            if (storedUserData) {
                setTokenAmount(storedUserData);
            }
        }
    }, [balance]);

    const BuyToken = async () => {
        if (!ISSERVER && user?.verifiedCredentials[0].address) {
            setBalance(amount)
            contract.connect(account0);

            const previousAmount = localStorage.getItem('amount')
            if (previousAmount) {
                localStorage.setItem('amount', parseInt(previousAmount) + amount);
            } else {
                localStorage.setItem('amount', amount);
            }

            const amountBigInt = BigInt(amount);
            console.log(amountBigInt * 1n * 10n ** 18n)

            const transferCall = contract.populate('transfer', {
                recipient: user?.verifiedCredentials[0].address,
                amount: amountBigInt * 1n * 10n ** 18n,
            });
            const { transaction_hash: transferTxHash } = await account0.execute(transferCall);
            // Wait for the invoke transaction to be accepted on Starknet
            console.log(`Waiting for Tx to be Accepted on Starknet - Transfer...`);
            await provider.waitForTransaction(transferTxHash);

            toast({
                title: "Success 🎉",
                description: `${amount} tokens have been successfully added to your balance`,
            })

        } else {
            alert('Please Connect Wallet')
        }
    }

    return (
        <FrameBox
            title={<div className='bg-no-repeat bg-top h-[96px] -translate-y-1/2'></div>}
            onClose={openHandler} // onClose prop for closing the component
            showClose={true} // Option to hide the close button
        >
            <div className='w-[560px] m-10 text-center flex flex-col justify-center text-white' data-testid="add fund">
                <h4 className='text-3xl font-black'>Add Tokens to Your Fund</h4>
                <p>Boost Your Stack, Elevate Your Game: Add Funds with Ease at starkdeck!</p>
                <section className='flex gap-8 w-fit mx-auto mt-4 mb-4'>
                    <button onClick={(event) => handleClick(event)}>
                        <img src="/chips-blank-1.png" data-value="1" />
                        <p>$ 1</p>
                    </button>
                    <button onClick={(event) => handleClick(event)}>
                        <img src="/chips-blank-4.png" data-value="5" />
                        <p>$ 5</p>
                    </button>
                    <button onClick={(event) => handleClick(event)}>
                        <img src="/chips-blank-2.png" data-value="10" />
                        <p>$ 10</p>
                    </button>
                    <button onClick={(event) => handleClick(event)}>
                        <img src="/chips-blank-3.png" data-value="100" />
                        <p>$ 100</p>
                    </button>
                </section>
                <div className='flex bg-black/20 justify-between items-center text-white font-semibold rounded-lg' style={{ padding: "10px 20px" }}>
                    <div className='bg-black/30 rounded-lg flex items-center justify-between' style={{ padding: "5px 20px", width: "66%" }}><span>{amount}</span> {amount != 0 && <button onClick={() => setAmount(0)}><RxCross2 /></button>}</div>
                    <Dialog>
                        <DialogTrigger asChild>
                            <StyledButton onClick={BuyToken}>Buy Token</StyledButton>
                        </DialogTrigger>
                        <DialogContent className="p-6 w-fit">
                            <DialogHeader>
                                <DialogTitle>Success 🎉</DialogTitle>
                                <DialogDescription className="text-lg">
                                    <img className='m-auto animate-bounce' src="/avatar-robot.png" />
                                    Your Token have been successfully added to your Balance
                                </DialogDescription>
                            </DialogHeader>
                        </DialogContent>
                    </Dialog>
                </div>
                <div className='mt-2 text-gray-200'>select tokens you want to buy</div>
            </div>
        </FrameBox>
    )
}