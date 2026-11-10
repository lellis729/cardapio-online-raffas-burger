# Configuração do painel Rafa Burger na Vercel

O código mantém o cardápio atual e usa Vercel Functions + Neon Postgres. Para não deixar pedidos e produtos apenas no navegador, conclua estes passos no projeto Vercel já existente:

1. No painel da Vercel, abra **Storage / Marketplace** e instale **Neon Postgres** no projeto Rafa Burger. A integração cria o banco e adiciona `DATABASE_URL` às variáveis do projeto.
2. No painel do Neon, abra o SQL Editor, cole o conteúdo de `schema.sql` e execute. Isso cria tabelas, índices e os produtos iniciais; seeds não sobrescrevem produtos existentes.
3. Em **Vercel → Settings → Environment Variables**, defina para **Production**:
   - `ADMIN_EMAIL`: e-mail que usará o painel.
   - `ADMIN_PASSWORD`: senha exclusiva forte (recomendado: 16 ou mais caracteres aleatórios).
   - `SESSION_SECRET`: pelo menos 32 bytes aleatórios, em texto. Gere localmente com PowerShell: `[Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(32))`.
4. Salve as variáveis e faça um novo deploy. O painel ficará em `/admin.html`.

Não envie `ADMIN_PASSWORD`, `SESSION_SECRET` ou `DATABASE_URL` ao navegador, ao Git ou ao chat. A URL pública `/acompanhar.html?token=...` é criada por pedido; o token aleatório autoriza apenas consultar o andamento daquele pedido.

O painel consulta pedidos e o cardápio a cada 5 segundos; pedidos novos também recebem destaque e alerta sonoro. Notificações do navegador dependem da permissão concedida pelo administrador. Fotos são gerenciadas por URL HTTPS; cole a URL da imagem no cadastro do produto ou deixe em branco para removê-la.

O cliente só recebe a confirmação de envio ao WhatsApp depois que o pedido foi persistido no banco. O total é recalculado no servidor usando o preço atual do produto, e pedidos guardam uma cópia dos itens e preços para preservar o histórico.
