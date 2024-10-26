import classNames from 'classnames'
import { displayAddress } from '@/util'
import StyledButton from './styled-button'
import { useState } from 'react'

export default function Player({
  user = {},
  isCurrentPlayer = false,
  cards = [],
  rightSide = false,
  children,
  showBitChips = true,
  style,
}) {
  const [ready, setReady] = useState(false)

  return (
    <div className='absolute inline-flex min-w-min h-2 bg-white' style={style}>
      <div className={
        classNames(
          'flex absolute min-w-[210px] h-16 border-2 left-0 top-0 p-2 rounded-lg',
          'border-black/80 bg-[rgb(50,50,50)] bg-gradient-to-b from-white/10 to-transparent shadow-[inset_0_1px_1px_rgba(255,255,255,.2),0_0_16px_rgba(0,0,0,.8)]',
          rightSide ? 'flex-row-reverse' : 'flex-row',
        )
      }>
        <div className={
          classNames(
            'flex grow flex-col h-full',
            rightSide ? 'pl-16' : 'pr-16',
          )
        }>
          {user && user.address && <div className='basis-1/2 font-extrabold text-white text-sm [text-shadow:0_0_4px_rgba(0,0,0,.4))]'>{displayAddress(user.address)}</div>}
        </div>
        <div className='flex-none w-0'>
        </div>
      </div>
      <div className={classNames('absolute -top-8', rightSide ? '-left-52' : 'left-64')}>
        {children}
      </div>
    </div>
  )
}