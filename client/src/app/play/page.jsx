'use client'

import StyledButton from '@/components/styled-button'
import { useRef, useEffect, useState } from 'react'
import { checkAddress, getUserData } from '@/util/databaseFunctions';
import { useRouter } from 'next/navigation';
import { DynamicWidget } from '@dynamic-labs/sdk-react-core';
import { useDynamicContext } from '@dynamic-labs/sdk-react-core';
import TokenInfoBar from '@/components/TokenBar'


export default function PlayGame() {

    const [accounts, setAccounts] = useState(null);
    const [open, setOpen] = useState(false)
    const [loading, setLoading] = useState(false)

    const router = useRouter()

    const { user } = useDynamicContext();

    const ISSERVER = typeof window === "undefined";

    const openHandler = () => {
        setOpen(false)
    }

    return (
        <div className='relative'>
            <TokenInfoBar />
            <div className='bg-white w-full max-w-[1280px] h-[720px] overflow-hidden mx-auto my-8 px-4 py-2 rounded-lg bg-cover bg-[url("/bg-2.jpg")] relative shadow-[0_0_20px_rgba(0,0,0,0.8)]'>
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
                    {user &&
                        <div className='flex flex-col items-center'>
                            <StyledButton onClick={() => router.push("/create")} className='w-fit bg-[#00b69a] bottom-4 text-2xl mt-6'>Create Table </StyledButton>
                            <StyledButton onClick={() => router.push("/game/join")} className='w-fit bg-[#00b69a] bottom-4 text-2xl mt-6'>Join Game </StyledButton>
                            {loading &&
                                <div className='text-white mt-2 text-2xl shadow-lg'>
                                    Wait, while we are retriving your details...
                                </div>
                            }
                        </div>
                    }
                </div>
            </div>
        </div >
    )
}