SELECT
    pvm.numero_pedido
    , pvm.data_pedido
    , pvm.status
    , pvm.cod_cliente
    , cli.nome
    , pppc.NFe
    , pppc.NFe_Aut
FROM pedidovendam pvm
RIGHT JOIN clientes cli ON cli.id = pvm.cod_clienteprazo_pagto_padrao_cliente
LEFT JOIN prazo_pagto_padrao_cliente pppc ON cli.id = pppc.id_cliente
WHERE CAST(pvm.data_pedido AS DATE) = CURRENT_DATE() - 2;