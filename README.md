# 🧠 Processador RISC-V Pipeline com Cache de Dados (32 bits)

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Verilog](https://img.shields.io/badge/Verilog-HDL-green)

Implementação em Verilog HDL de um processador RISC-V com arquitetura pipeline de 5 estágios e cache de dados com mapeamento direto. Desenvolvido como projeto acadêmico na disciplina de Arquitetura de Computadores.

---

## 📑 Sumário

- [📌 Visão Geral](#-visão-geral)
- [⚙️ Arquitetura do Pipeline](#-arquitetura-do-pipeline)
- [🧱 Componentes Implementados](#-componentes-implementados)
- [📉 Controle de Hazards](#-controle-de-hazards)
- [🧮 Cache de Dados](#-cache-de-dados)
- [🧪 Simulação e Testes](#-simulação-e-testes)
- [🔍 Resultados](#-resultados)
- [🚀 Como Rodar](#-como-rodar)
- [📚 Referências](#-referências)

---

## 📌 Visão Geral

Este projeto descreve o desenvolvimento de um processador escalar de 32 bits baseado em um subconjunto da ISA **RISC-V**, com pipeline de 5 estágios e mecanismos de otimização de desempenho como:
- **Forwarding de dados**
- **Detecção de hazards de carga-uso**
- **Cache de dados mapeada diretamente (write-through)**

O objetivo é estudar e simular uma microarquitetura moderna com foco em desempenho e integridade na execução paralela de instruções.

---

## ⚙️ Arquitetura do Pipeline

O pipeline é composto por 5 estágios clássicos:

| Estágio | Nome                    | Função Principal |
|--------:|-------------------------|------------------|
| IF      | Instruction Fetch       | Busca a instrução da memória de instruções |
| ID      | Instruction Decode      | Decodifica a instrução, lê registradores e imediato |
| EX      | Execute                 | Executa operações na ALU |
| MEM     | Memory Access           | Acessa a memória de dados (load/store) |
| WB      | Write Back              | Escreve resultados no banco de registradores |

A comunicação entre estágios é feita através de **registradores de pipeline** (IF/ID, ID/EX, EX/MEM, MEM/WB).

---

## 🧱 Componentes Implementados

- `alu.v` – Unidade Aritmética e Lógica
- `reg_file.v` – Banco de registradores com 32 posições
- `control_unit.v` – Unidade de controle de sinais
- `forwarding_unit.v` – Unidade de adiantamento (data hazard forwarding)
- `hazard_unit.v` – Unidade de detecção de carga-uso
- `instruction_memory.v` – Memória ROM para instruções
- `data_memory.v` – Memória RAM principal
- `direct_mapped_cache.v` – Cache de dados de mapeamento direto
- `processor_top.v` – Módulo principal integrador dos estágios
- `top_tb.v` – Testbench principal com simulação no ModelSim

---

## 📉 Controle de Hazards

### ✅ Data Hazards (RAW)

Implementado por meio de uma **Unidade de Forwarding**, que detecta dependências entre os registradores e redireciona os dados ainda não escritos para evitar stalls.

### ⚠️ Load-Use Hazards

Quando uma instrução `lw` é imediatamente seguida por uma instrução que depende do dado carregado, a **Unidade de Hazards** insere uma **bolha (NOP)** e congela o PC e IF/ID.

---

## 🧮 Cache de Dados

- **Tipo**: Mapeamento Direto
- **Tamanho**: 256 linhas (1KB)
- **Política de Escrita**: Write-through
- **Controle por FSM** com estados:
  - `IDLE`
  - `MEM_READ`
  - `MEM_WRITE`

Em caso de cache **miss**, um sinal de **congelamento do pipeline** é ativado até que o dado seja recuperado da memória.

---

## 🧪 Simulação e Testes

A verificação funcional foi feita no **ModelSim**, com um testbench customizado para forçar os seguintes cenários:

- `Write Miss`: Escrita inicial em um endereço novo
- `Read Hit`: Leitura subsequente do mesmo endereço
- `Conflict Miss`: Leitura de um endereço que mapeia para o mesmo índice da cache
- `Re-hit`: Leitura do endereço original após conflito

---

## 🔍 Resultados

- `Mem[32] = 77`: Escrita com sucesso via cache
- `x5 = 77`: Leitura após hit validada
- `x7 = 77`: Leitura após conflito e nova substituição funcionando corretamente
- `x6 = x`: Instrução atrasada que não chegou a WB (esperado no teste)

Todos os **eventos de stall**, **cache hit** e **miss** ocorreram exatamente nos ciclos esperados, confirmando a integridade do pipeline.

---

## 🚀 Como Rodar

1. Instale o **ModelSim** (ou outra ferramenta de simulação Verilog compatível)
2. Compile todos os módulos Verilog
3. Execute o testbench `top_tb.v`
4. Analise os sinais através do terminal ou da waveform (`.vcd`)

```sh
vlog *.v
vsim testbanch.v
run -all
