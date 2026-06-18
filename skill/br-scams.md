# Reference: br-scams (padrões BR — PT)

Referência curta em português para padrões de golpe recorrentes no público
brasileiro de Solana. Carregue quando o contexto for BR (Telegram/X em PT, KOL
local, grupo de "sinais") ou quando o usuário pedir explicitamente. Mapeia cada
padrão para o endpoint que ajuda a checá-lo.

> Os veredictos são auditáveis por mint em `/v1/predictions/{mint}`. Todo número
> citado deve ser puxado ao vivo (`/v1/stats`) — nunca de um doc.

## 1. Pump de KOL / grupo de Telegram

Influencer ou grupo "VIP" anuncia um token novo; compra coordenada no mesmo
bloco; deployer dropa a liquidez minutos depois.

- **Como checar:** `check_token(mint)` → olhar `deployer` e `deployer_risk_level`.
  Em seguida `check_operator(deployer)` — se o operador já tem rugs confirmados,
  o "lançamento exclusivo" é reincidência.
- **Sinal forte:** `risk_level` CRITICAL/HIGH + flags de concentração
  (`TOP_HOLDER_OWNS_>50%`) ou bundle (`SAME_BLOCK_BUYERS_>10`).

## 2. Address poisoning / vanity lookalike

Atacante "envenena" seu histórico com um endereço cujo início/fim imita uma
carteira que você usa, esperando que você copie o errado na próxima transferência.

- **Como checar:** `GET /v1/lookalike-check?destination=<addr>&contacts=<suas_carteiras>`.
  `suspect:true` ⇒ o destino imita um contato seu — você provavelmente quis o contato.
- Ver `tx-preview.md`. Match de prefixo/sufixo **não** é prova de carteira-irmã —
  é armadilha de copiar-colar.

## 3. Impersonação de grant / programa (SuperteamBR, Colosseum, "airdrop oficial")

DM ou site falso pedindo para "conectar wallet" ou assinar uma transação para
"liberar" um grant/airdrop. O dano vem da **assinatura**, não de um token.

- **Como checar:** `tx-preview.md` (`POST /v1/tx-preview`) **antes de assinar** —
  os detectores `owner_reassignment` / `close_account` / `stake_authority` pegam
  a tomada de autoridade típica desse golpe.
- Regra: programa/portal oficial nunca precisa que você assine transferência de
  autoridade de conta para "receber" algo.

## 4. Rebrand / serial deployer

Mesma carteira relança o mesmo golpe com nome/símbolo novo (tag `rebrand_artist`,
padrão `fast_deployer`). O token parece novo; o operador não é.

- **Como checar:** `check_operator(deployer)` — `patterns`/`tags` expõem o histórico
  mesmo quando o token é "do dia".

## Saída (como responder em PT)

- Lidere com o veredicto (CRITICAL/HIGH/MEDIUM); trate LOW como não-decisivo.
- Para `UNKNOWN`: "não está na base de operadores rastreados" — **nunca** "é seguro".
- Ofereça o link de verificação: `https://solsentry.app/operator/{wallet}`.
