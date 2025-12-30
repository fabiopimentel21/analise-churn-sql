with base_contratos as (
    select
        distinct
        c.nr_central_sigma,
        ccc.codigo_contrato,
        ccc.data_pedido as data_inicio,
        ccc.data_rescisao,
        (
            select mcc.situacao
            from movimento_contratos_cli mcc
            where mcc.codigo_contrato = ccc.codigo_contrato
              and mcc.situacao <> 7
            order by mcc.data_conclusao desc
            limit 1
        ) as situacao_movimento
    from clientes c
    inner join cab_contratos_cli ccc on ccc.codigo_cliente = c.codigo_cliente
),

clientes_com_contrato_ativo as (
    select distinct nr_central_sigma
    from base_contratos
    where data_rescisao is null
),

churn_por_cliente as (
    select
        bc.nr_central_sigma,
        MAX(bc.data_rescisao) as data_churn
    from base_contratos bc
    where bc.data_rescisao is not null
      and bc.nr_central_sigma not in (select nr_central_sigma from clientes_com_contrato_ativo)
    group by bc.nr_central_sigma
),

data_minima as (
    -- Busca o mês do primeiríssimo contrato
    select date_trunc('month', min(data_inicio)) as inicio_historico 
    from base_contratos
),

churn_mensal as (
    select
        DATE_TRUNC('month', ch.data_churn) as mes_churn,
        COUNT(distinct ch.nr_central_sigma) as clientes_churn
    from churn_por_cliente ch
    group by 1
),

clientes_ativos_inicio_mes as (
    select
        sm.mes,
        COUNT(distinct bc.nr_central_sigma) as total_clientes_inicio
    from (
        select generate_series(
            (select inicio_historico from data_minima),
            CURRENT_DATE,
            '1 month'
        )::date as mes
    ) sm
    cross join base_contratos bc
    where bc.data_inicio < sm.mes
      and (bc.data_rescisao is null or bc.data_rescisao >= sm.mes)
    group by sm.mes
)

select
    TO_CHAR(cam.mes, 'YYYY-MM') as periodo,
    cam.total_clientes_inicio as clientes_no_inicio_do_mes,
    coalesce(cm.clientes_churn, 0) as total_churn_no_mes,
    case
        when cam.total_clientes_inicio = 0 then 0
        else ROUND((coalesce(cm.clientes_churn, 0)::numeric / cam.total_clientes_inicio::numeric) * 100, 2)
    end as churn_rate_percentual,
    -- Sua regra de ouro: acima de 2% é ruim
    case 
        when (coalesce(cm.clientes_churn, 0)::numeric / nullif(cam.total_clientes_inicio,0)::numeric) * 100 > 2.0 then 'CRÍTICO (>2%)'
        when (coalesce(cm.clientes_churn, 0)::numeric / nullif(cam.total_clientes_inicio,0)::numeric) * 100 > 1.5 then 'ALERTA'
        else 'SAUDÁVEL'
    end as status_saude
from clientes_ativos_inicio_mes cam
left join churn_mensal cm on cam.mes = cm.mes_churn
where cam.total_clientes_inicio > 0
order by cam.mes;
