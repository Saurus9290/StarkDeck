
import StyledButton from '@/components/styled-button'
import classNames from 'classnames'
import { useState } from 'react'


function BlankChip({ index = 0, setShowChipPanel, showChipPanel }) {

  return (
    <div
      className={classNames(
        'cursor-pointer w-20 h-20 relative transition-transform before:duration-300 before:transition-opacity before:opacity-0 before:bg-yellow-500 hover:before:opacity-100 before:rounded-full before:blur-sm before:absolute before:w-full before:h-full before:block',
        'hover:before:opacity-100 hover:-translate-y-4',
      )}
      onClick={() => {
        setShowChipPanel(true)
      }}
    >
      <div className='scale-[0.54] origin-top-left'>
        <div
          className={'bg-no-repeat relative bg-contain flex items-center justify-center font-black text-white text-5xl'}
          style={{
            width: 148, height: 148,
            backgroundImage: `url("/chips-blank-${index + 1}.png")`
          }}
        >{value}</div>
      </div>
    </div>
  )
}

export default function BottomController() {

  const [showChipPanel, setShowChipPanel] = useState(false)

  return (
    <>
      <div className='absolute left-2 bottom-2 right-2 flex gap-2 items-center justify-center'>
        <div className='items-fold'>
          <StyledButton className='bg-red-600 mr-40'
            onClick={() => {
            }}
          ><div className='h-10 inline-flex items-center'>FOLD</div></StyledButton>
        </div>
        <div>
          <StyledButton className={classNames('bg-[rgb(255,150,0)] transition-transform', showChipPanel ? 'translate-y-40' : 'translate-y-0')}
            onClick={() => setShowChipPanel(true)}
          ><div className='h-10 inline-flex items-center'>RAISE</div></StyledButton>
        </div>
        {
          <div>
            <StyledButton className='bg-[#00bb5c]'
            ><div className='h-10 inline-flex items-center'>CALL</div></StyledButton>
          </div>
        }
      </div>


      <div className={classNames(
        'w-full h-full absolute -left-50 bottom-0 pb-2 transform-gpu transition-transform bg-no-repeat bg-bottom bg-[url("/table_bottom.png")] flex items-end justify-center gap-2',
        showChipPanel ? 'translate-y-0 pointer-events-auto' : 'translate-y-32 pointer-events-none'
      )}
      >
        <BlankChip index={0} showChipPanel={showChipPanel} setShowChipPanel={setShowChipPanel} />
        <BlankChip index={1} showChipPanel={showChipPanel} setShowChipPanel={setShowChipPanel} />
        <BlankChip index={2} showChipPanel={showChipPanel} setShowChipPanel={setShowChipPanel} />
        <BlankChip index={3} showChipPanel={showChipPanel} setShowChipPanel={setShowChipPanel} />
        <BlankChip index={4} showChipPanel={showChipPanel} setShowChipPanel={setShowChipPanel} />
        <BlankChip index={5} showChipPanel={showChipPanel} setShowChipPanel={setShowChipPanel} />
        <div className='cursor-pointer absolute bottom-[30px] right-[280px] bg-contain bg-[url("/close-icon-3.png")] w-[38px] h-[38px]'
          onClick={() => setShowChipPanel(false)}
        ></div>
      </div>
    </>
  )
}