'use client'

import GameRoom from '@/app/game/room';
import { useState } from 'react'
import TokenInfoBar from '../TokenBar';

export default function Game() {

    const [walletConnected, setWalletConnected] = useState(false);
    const [userInfo, setUserInfo] = useState(null);
    const [accounts, setAccounts] = useState(null);
    const [loading, setLoading] = useState(true);
    const [open, setOpen] = useState(false)


    return (
        <div>
            <TokenInfoBar />
            <GameRoom />
        </div>
    )
}