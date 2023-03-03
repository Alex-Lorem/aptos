module nft::goober_goblins {
    use std::signer;
    use std::string::{Self, String};
    use std::vector;
    use aptos_framework::coin::{Self};
    use aptos_framework::account;
    use aptos_token::token::{Self};


    const INVALID_SIGNER: u64 = 0;
    const INVALID_AMOUNT: u64 = 1;
    const ESALE_NOT_STARTED: u64 = 2;
    const ESOLD_OUT: u64 = 3;
    const INVALID_UPDATE_NUMBER: u64 = 4;

    struct GooberGoblins has key {
        collection_name: String,
        collection_description: String,
        baseuri: String,
        royalty_payee_address: address,
        royalty_points_denominator: u64,
        royalty_points_numerator: u64,
        presale_mint_price: u64,
        public_sale_mint_price: u64,
        paused: bool,
        total_supply: u64,
        minted: u64,
        token_mutate_setting: vector<bool>,
        whitelist: vector<address>,
    }

    struct ResourceInfo has key {
        source: address,
        resource_cap: account::SignerCapability
    }

    fun init_module(account: &signer) {
        let collection_name = string::utf8(b"GooberGoblins");
        let collection_description = string::utf8(b"There was once a secret science lab that was created to experiment with radioactive OOZE. The OOZE was unstable, and it ended up contaminating the entire lab. The scientists and their samples were turned into Goober Goblins, the lab was flooded with OOZE.");
        let baseuri = string::utf8(
            b"https://gateway.pinata.cloud/ipfs/QmWomCG8h9szQ5Zdoe4F1pCLtuVwvJ7nUzqW7aJCmZEH7A/"
        );
        let royalty_payee_address = signer::address_of(account);
        let royalty_points_denominator: u64 = 100;
        let royalty_points_numerator: u64 = 5;
        let presale_mint_price: u64 = 5000000;
        let public_sale_mint_price: u64 = 10000000;
        let total_supply: u64 = 10000;
        let token_mutate_setting = vector<bool>[true, true, true, true, true];
        let collection_mutate_setting = vector<bool>[true, true, true];
        let (_resource, resource_cap) = account::create_resource_account(account, vector<u8>[1]);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_cap);
        move_to<ResourceInfo>(
            &resource_signer_from_cap,
            ResourceInfo { resource_cap, source: signer::address_of(account) }
        );
        let whitelist = vector::empty<address>();
        move_to<GooberGoblins>(&resource_signer_from_cap, GooberGoblins {
            collection_name,
            collection_description,
            baseuri,
            royalty_payee_address,
            royalty_points_denominator,
            royalty_points_numerator,
            presale_mint_price,
            public_sale_mint_price,
            total_supply,
            minted: 1,
            paused: true,
            token_mutate_setting,
            whitelist
        });
        token::create_collection(
            &resource_signer_from_cap,
            collection_name,
            collection_description,
            baseuri,
            0,
            collection_mutate_setting
        );
    }

    public entry fun create_whitelist(
        account: &signer,
        collection: address,
        whitelist: vector<address>
    )acquires GooberGoblins, ResourceInfo {
        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(collection);
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let collection_data = borrow_global_mut<GooberGoblins>(collection);
        vector::append(&mut collection_data.whitelist, whitelist);
    }

    public entry fun owner_mint_script(
        receiver: &signer,
        collection: address,
        amount: u64
    ) acquires ResourceInfo, GooberGoblins {
        let account_addr = signer::address_of(receiver);
        let resource_data = borrow_global<ResourceInfo>(collection);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_data.resource_cap);
        let collection_data = borrow_global_mut<GooberGoblins>(collection);
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        assert!(collection_data.minted + amount <= collection_data.total_supply, ESOLD_OUT);

        let i = 0;

        while (i < amount) {
            let baseuri = collection_data.baseuri;
            let owl = collection_data.minted;
            let properties_keys = vector<String>[string::utf8(b"TOKEN_BURNABLE_BY_OWNER")];
            let properties_types = vector<String>[string::utf8(b"bool")];

            string::append(&mut baseuri, num_str(owl));

            let token_name = string::utf8(b"Goober Goblin");
            string::append(&mut token_name, string::utf8(b" #"));
            string::append(&mut token_name, num_str(owl));
            string::append(&mut baseuri, string::utf8(b".json"));


            token::create_token_script(
                &resource_signer_from_cap,
                collection_data.collection_name,
                token_name,
                collection_data.collection_description,
                1,
                0,
                baseuri,
                collection_data.royalty_payee_address,
                collection_data.royalty_points_denominator,
                collection_data.royalty_points_numerator,
                collection_data.token_mutate_setting,
                properties_keys,
                vector<vector<u8>>[vector<u8>[1]],
                properties_types
            );
            let token_data_id = token::create_token_data_id(collection, collection_data.collection_name, token_name);
            token::opt_in_direct_transfer(receiver, true);
            token::mint_token_to(&resource_signer_from_cap, account_addr, token_data_id, 1);
            collection_data.minted = collection_data.minted + 1;
            i = i + 1;
        };
    }

    public entry fun mint_script(
        receiver: &signer,
        collection: address,
        amount: u64
    ) acquires ResourceInfo, GooberGoblins {
        let receiver_addr = signer::address_of(receiver);
        let resource_data = borrow_global<ResourceInfo>(collection);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_data.resource_cap);
        let collection_data = borrow_global_mut<GooberGoblins>(collection);
        assert!(collection_data.paused == false, ESALE_NOT_STARTED);
        assert!(collection_data.minted + amount <= collection_data.total_supply, ESOLD_OUT);
        let i = 0;

        while (i < amount) {

            let owl = collection_data.minted;

            let properties = vector::empty<String>();

            let token_name = string::utf8(b"Goober Goblin");

            string::append(&mut token_name, string::utf8(b" #"));
            string::append(&mut token_name, num_str(owl));

            let baseuri = collection_data.baseuri;

            string::append(&mut baseuri, num_str(owl));
            string::append(&mut baseuri, string::utf8(b".json"));


            token::create_token_script(
                &resource_signer_from_cap,
                collection_data.collection_name,
                token_name,
                collection_data.collection_description,
                1,
                0,
                baseuri,
                collection_data.royalty_payee_address,
                collection_data.royalty_points_denominator,
                collection_data.royalty_points_numerator,
                collection_data.token_mutate_setting,
                properties,
                vector<vector<u8>>[],
                properties
            );

            let token_data_id = token::create_token_data_id(collection, collection_data.collection_name, token_name);
            token::opt_in_direct_transfer(receiver, true);

            token::mint_token_to(&resource_signer_from_cap, receiver_addr, token_data_id, 1);
            collection_data.minted = collection_data.minted + 1;
            i = i + 1;
        };
        let mint_price = collection_data.public_sale_mint_price;
        if (vector::contains(&collection_data.whitelist, &receiver_addr)) {
            //if (now > collection_data.presale_mint_time && now < collection_data.public_sale_mint_time) {
                mint_price = collection_data.presale_mint_price
            //};
        };
        let price = mint_price * amount;
        coin::transfer<0x1::aptos_coin::AptosCoin>(receiver, resource_data.source, price);
    }

    public entry fun update_uri(account: &signer, uri: String, collection: address, number: u64, updateMore: u8) acquires ResourceInfo, GooberGoblins {

        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(collection);
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let collection_data = borrow_global_mut<GooberGoblins>(collection);
        collection_data.baseuri = uri;
        assert!(number == 2500 || number == 5000 || number == 7500 || number == 10000, INVALID_UPDATE_NUMBER);
        assert!(updateMore == 0 || updateMore == 1, INVALID_UPDATE_NUMBER);

        let signer_cap = &borrow_global<ResourceInfo>(collection).resource_cap;
        let resource_signer_from_cap = account::create_signer_with_capability(signer_cap);
        let i = 1;
        if(updateMore == 0){
            if(number == 5000){
                i = 2501
            } else if(number == 7500){
                i = 5001
            } else if(number == 10000){
                i = 7501
            };
        } else {
            if(number == 2500){
                i = 2501;
            } else if(number == 5000){
                i = 5001
            } else if (number == 7500){
                i = 7501
            };
            number = collection_data.minted;
        };



        while(i <= number){
            let token_name = string::utf8(b"Goober Goblin");
            string::append(&mut token_name, string::utf8(b" #"));
            string::append(&mut token_name, num_str(i));

            let new_uri = uri;
            string::append(&mut new_uri, num_str(i));
            string::append(&mut new_uri, string::utf8(b".json"));

            let token_id = token::create_token_data_id(collection, collection_data.collection_name, token_name);

            token::mutate_tokendata_uri(&resource_signer_from_cap, token_id, new_uri);

            i = i + 1;
        };

    }

    public entry fun burn(account: &signer, collection: address, from: u64, to: u64, prop: u64) acquires ResourceInfo, GooberGoblins {
        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(collection);
        let collection_data = borrow_global_mut<GooberGoblins>(collection);
        assert!(resource_data.source == account_addr, INVALID_SIGNER);

        let i = from;
        while(i <= to){
            let token_name = string::utf8(b"Goober Goblin");
            string::append(&mut token_name, string::utf8(b" #"));
            string::append(&mut token_name, num_str(i));

            token::burn(account, collection, collection_data.collection_name, token_name, prop, 1);
            i = i + 1;
        };

    }

    public entry fun pause_mint(
        admin: &signer,
        collection: address
    )acquires GooberGoblins, ResourceInfo {
        let account_addr = signer::address_of(admin);
        let resource_data = borrow_global<ResourceInfo>(collection);
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let collection_data = borrow_global_mut<GooberGoblins>(collection);
        collection_data.paused = true;
    }

    public entry fun resume_mint(
        admin: &signer,
        collection: address
    )acquires GooberGoblins, ResourceInfo {
        let account_addr = signer::address_of(admin);
        let resource_data = borrow_global<ResourceInfo>(collection);
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let collection_data = borrow_global_mut<GooberGoblins>(collection);
        collection_data.paused = false;
    }

    public entry fun update_collection(
        admin: &signer,
        royalty_points_denominator: u64,
        royalty_points_numerator: u64,
        public_sale_mint_price: u64,
        presale_mint_price: u64,
        collection: address
    )acquires GooberGoblins, ResourceInfo {
        let account_addr = signer::address_of(admin);
        let resource_data = borrow_global<ResourceInfo>(collection);
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let collection_data = borrow_global_mut<GooberGoblins>(collection);

        if (royalty_points_denominator > 0) {
            collection_data.royalty_points_denominator = royalty_points_denominator
        };
        if (royalty_points_numerator > 0) {
            collection_data.royalty_points_numerator = royalty_points_numerator
        };
        if(presale_mint_price > 0){
            collection_data.presale_mint_price = presale_mint_price;
        };
        if(public_sale_mint_price > 0){
            collection_data.public_sale_mint_price = public_sale_mint_price;
        };

    }

    fun num_str(num: u64): String {
        let v1 = vector::empty();
        while (num / 10 > 0) {
            let rem = num % 10;
            vector::push_back(&mut v1, (rem + 48 as u8));
            num = num / 10;
        };
        vector::push_back(&mut v1, (num + 48 as u8));
        vector::reverse(&mut v1);
        string::utf8(v1)
    }
}
