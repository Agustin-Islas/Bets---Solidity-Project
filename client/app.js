App = {

    contracts: {},

    init: async () => {
        console.log('Loaded')
        await App.loadEthereum()
        await App.loadAccount()
        await App.loadContracts()
        App.render()
        await App.renderBets()
    },
    
    loadEthereum: async () => {
        if (window.ethereum) {
            App.web3provider = window.ethereum;
            await window.ethereum.request({method: 'eth_requestAccounts'})
        } else if (window.web3) {
            web3 = new Web3(window.web3.currentProvider)
        } else {
            console.log('ethereum no existe');
        }
    },

    loadContracts: async () => {
        const res = await fetch("Bets.json")
        const betsContractJSON = await res.json()

        App.contracts.betsContract = TruffleContract(betsContractJSON)
        
        App.contracts.betsContract.setProvider(App.web3provider)
        
        App.betsContract = await App.contracts.betsContract.deployed()
        console.log(App.betsContract)
    },

    loadAccount: async () => {
        const accounts = await window.ethereum.request({method: 'eth_requestAccounts'})
        App.account = accounts[0];
    },

    render: () => {
        document.getElementById('account').innerText = App.account
    },

    createBet: async (optionA, optionB) => {
        const result = await App.betsContract.createBet(optionA, optionB, {
            from: App.account,
        });
    },
    test: async (optionA, optionB) => {
        const result = await App.betsContract.test(optionA, optionB, {
            from: App.account,
        });
    },
    renderBets: async () => {
        const betsCounter = await App.betsContract.betsCounter()
        
        let html = ''

        //  await App.createBet("equipo A", "equipo B")        

        for (let i = 0; i < betsCounter; i++) {
            const bet = await App.betsContract.bets(i)
            
            const betId = bet[0];
            const poolA = bet[1];
            const poolB = bet[2];
            const poolDraw = bet[3];
            const optionA = bet[4];
            const optionB = bet[5];
            const optionC = bet[6];
            const state = bet[7];
            const winner = bet[8];

            let betElement = `<h4>ID: ${betId} ${optionA} vs  ${optionB} </h4>`
            if (state == 0) {
                betElement += `<h4> Active \n</h4>`
            } else {
                betElement += `<h4> Finalized \n</h4>`
            }

            if (winner == 0) {
                betElement += `<h4> Winner: ${optionA} \n</h4>`
            } else if (winner == 1) {
                betElement += `<h4> Winner: ${optionB} \n</h4>`
            } else if (winner == 2) {
                betElement += `<h4> Winner: ${optionC} \n</h4>`
            } else {
                betElement += `<h4> Winner: undefine.. \n</h4>`
            }

            html += betElement;
        }
        document.querySelector('#betsList').innerHTML = html;
    }
}

App.init();