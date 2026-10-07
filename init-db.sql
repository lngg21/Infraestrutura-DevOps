-- Script de Inicialização dos Bancos de Dados PostgreSQL
-- Este script cria os dois bancos de dados necessários para os microsserviços

SELECT 'CREATE DATABASE contracts_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'contracts_db')\gexec

SELECT 'CREATE DATABASE flash_sales'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'flash_sales')\gexec
