# Processador RISC-V Monociclo em Verilog

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Verilog](https://img.shields.io/badge/Verilog-ES--module-green)

Implementação de um processador RISC-V monociclo capaz de executar o algoritmo Quicksort, desenvolvido como projeto de arquitetura de computadores.

## 📋 Tabela de Conteúdos
- [Visão Geral](#-visão-geral)
- [Funcionalidades](#-funcionalidades)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Instruções Suportadas](#-instruções-suportadas)
- [Como Usar](#-como-usar)
- [Simulação](#-simulação)
- [Licença](#-licença)

## 🌟 Visão Geral
Este projeto implementa um processador RISC-V monociclo em Verilog com os seguintes componentes principais:
- Unidade de Controle
- ULA (Unidade Lógica Aritmética)
- Banco de Registradores (32 registradores x 32 bits)
- Memória de Dados (1KB)
- Memória de Instruções (1KB)
- PC (Program Counter) com lógica de controle

## 🚀 Funcionalidades
- Execução de um subconjunto de instruções RISC-V
- Implementação do algoritmo Quicksort em hardware
- Mecanismo de load/store para acesso à memória
- Suporte a operações aritméticas e lógicas básicas
- Controle de fluxo com instruções de desvio

## 📂 Estrutura do Projeto