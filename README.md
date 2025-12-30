# Analise-churn-sql
codigo-sql
# 📊 Monitoramento de Churn Rate com SQL

Este projeto apresenta uma solução em SQL (PostgreSQL) para o cálculo dinâmico da taxa de cancelamento (**Churn Rate**) e classificação da saúde da base de clientes mês a mês.

## 🚀 O Problema de Negócio
O Churn Rate é uma métrica crítica para empresas de receita recorrente. O desafio técnico aqui foi:
1. Identificar quem era a base ativa exatamente no **primeiro dia** de cada mês.
2. Isolar clientes que cancelaram e não possuem outros contratos ativos (Churn real).
3. Classificar o status de saúde com base em KPIs de negócio (Regra: >2% é crítico).

## 🛠️ Lógica da Solução
A query foi estruturada utilizando **CTEs (Common Table Expressions)** para garantir legibilidade e performance:

1. **`base_contratos`**: Consolida as informações principais e busca a última situação do contrato via subquery.
2. **`clientes_com_contrato_ativo`**: Filtra clientes que possuem ao menos um contrato sem data de rescisão.
3. **`churn_por_cliente`**: Identifica a data exata em que o cliente deixou de ser cliente (quando todos os seus contratos foram encerrados).
4. **`clientes_ativos_inicio_mes`**: Utiliza `generate_series` para criar uma linha do tempo e cruza com a base para contar quantos clientes estavam "vivos" no início de cada período.

## 📈 Exemplo de Saída
A query gera um relatório pronto para dashboards:

| Periodo | Clientes Início | Total Churn | Churn Rate % | Status Saúde |
| :--- | :--- | :--- | :--- | :--- |
| 2024-01 | 1,250 | 12 | 0.96% | ✅ SAUDÁVEL |
| 2024-02 | 1,310 | 28 | 2.14% | 🚨 CRÍTICO (>2%) |

## 🧠 Conceitos Técnicos Aplicados
* **Window Functions / Subqueries:** Para buscar o último status de movimento.
* **Séries Temporais:** Geração de datas dinâmicas.
* **Lógica de Coalesce e NullIf:** Para evitar erros de divisão por zero e tratar campos nulos.
* **Case When:** Para implementação de regras de negócio diretamente na camada de dados.
