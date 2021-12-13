# Peg Insurance

Pegged by Yearn offers binary options to insure that stablecoins keep their peg.

You mint 1 collateral for 1 KEEPPEG and 1 LOSEPEG token. 

If the oracle price of the chainlink oracle at **_oracle** drops below the designated **_unpeggedPrice** before the **_expiry** then the the market can be settled as **UNPEGGED** and the LOSEPEG token can be redeemed for 1 collateral. 

If **_expiry** is reached before the the market is settled, then it can be settled as **PEGGED** and 1 KEEPPEG token can be redeemed for 1 collateral.

It is intended that the KEEPPEG and LOSEPEG tokens are traded on AMMs to create a market for the insurance product.