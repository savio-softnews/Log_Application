# Aplicador de Log - Automação de Backup do SGD

Automação em lote (`.bat`) desenvolvida para simplificar e padronizar o processo de **aplicação de logs em bancos de dados provenientes do SGD**, sejam eles backups do **banco DW** ou backups em **Nuvem**.  
A ferramenta automatiza a **descompactação**, **restauração** e **aplicação de logs**, além de gerar um **relatório de execução** para análise e controle de tempo.

---

## 🧩 Requisitos

Antes de executar o script, certifique-se de que os seguintes componentes estão instalados **nos caminhos padrão**:

- **7-Zip** → `C:\Program Files\7-Zip\7zG.exe`  
- **SQL Anywhere 17** → `C:\Program Files\SQL Anywhere 17\Bin64\dbeng17.exe`

> ⚠️ O programa atualmente funciona **somente** com backups baixados do **SGD (banco DW ou backup em Nuvem)**.

---

## ⚙️ Estrutura de Pastas

Crie uma pasta de trabalho com a seguinte estrutura:

```
📁 PastaPrincipal
 ┣ 📄 LogApplication.bat
 ┣ 📦 Backup_Completo.dom
 ┗ 📦 Backup_Modificacao.dom
```

> Não é necessário descompactar os arquivos `.dom`.

Durante a execução, o script criará automaticamente:
- `M` → arquivos temporários e descompactações do backup de modificação  
- `Logs` → registros e logs de execução

---

## ▶️ Execução

1. Crie uma nova pasta e adicione:
   - O **backup completo** (`.dom`)
   - O **backup de modificação** (`.dom`)
   - O arquivo **`LogApplication.bat`**

2. Execute o arquivo `.bat` com duplo clique.

3. Quando solicitado:
   ```
   As senhas de descompactacao sao a senha padrao? (S/N)
   ```
   - Se **S**, o script usará a senha padrão.
   - Se **N**, o usuário será solicitado a informar manualmente as senhas corretas para cada backup.

4. O script descompactará os arquivos, aplicará os logs e, ao final, criará o arquivo **`texto.txt`**, que conterá:
   - Tempos de execução
   - Etapas realizadas
   - Logs de erros ou sucesso

---

## 🧠 Passo a Passo Técnico Interno

Esta seção descreve tecnicamente o que o script `.bat` realiza em cada etapa.

### 1. Configuração inicial
- Define o uso de **UTF-8** (`chcp 65001`) para evitar problemas com acentuação.
- Define caminhos padrão:
  ```bat
  set "seteZipPath=C:\Program Files\7-Zip\7zG.exe"
  set "dbengPath=C:\Program Files\SQL Anywhere 17\Bin64\dbeng17.exe"
  ```
- Cria variáveis de diretório (`%~dp0`, `M`, `Logs`) para organizar os arquivos gerados.

### 2. Coleta de senhas
- O usuário é perguntado se deseja usar a senha padrão.
- Caso negativo, o script solicita as senhas para:
  - **Backup de modificação**
  - **Backup completo**

### 3. Descompactação dos backups
- Usa o **7-Zip** em modo gráfico (`7zG.exe`) para descompactar os arquivos `.dom`.
  ```bat
  "%seteZipPath%" x "Backup_Completo.dom" -p%senhaC% -o"%diretorioAtual%\C" -y
  "%seteZipPath%" x "Backup_Modificacao.dom" -p%senhaM% -o"%diretorioAtual%\M" -y
  ```
- Os conteúdos são extraídos para as pastas `C` e `M`.

### 4. Inicialização do banco e aplicação de logs
- Executa o **SQL Anywhere 17** (`dbeng17.exe`) apontando para o banco descompactado.
- Inicia o banco com parâmetros de controle e logs.
- Executa comandos SQL de atualização e aplica os logs contidos no backup de modificação.

### 5. Geração do relatório de tempos
- Mede e armazena os tempos de:
  - Descompactação dos backups  
  - Aplicação dos logs  
  - Finalização da operação
- Cria o arquivo `texto.txt` na pasta principal, contendo:
  - Tempo total de execução  
  - Caminhos dos arquivos utilizados  
  - Resultados e status final

### 6. Limpeza e encerramento
- Opcionalmente remove arquivos temporários.
- Exibe mensagem final informando a conclusão da aplicação dos logs.

---

## 📄 Saída Gerada

Após a execução, são criados:
- `texto.txt` → relatório detalhado com tempos e resultados da execução  
- `M` e `Logs` → pastas contendo arquivos temporários e de log

---

## 🧰 Troubleshooting (Solução de Problemas)

| Problema | Possível Causa | Solução |
|-----------|----------------|----------|
| Erro ao descompactar backup | Caminho incorreto do 7-Zip | Verifique se o 7-Zip está instalado em `C:\Program Files\7-Zip\7zG.exe` |
| Banco não inicializa | Caminho incorreto do SQL Anywhere | Confirme a instalação em `C:\Program Files\SQL Anywhere 17\Bin64\dbeng17.exe` |
| Script não executa | Falta de permissões | Execute o `.bat` como **Administrador** |
| Senha incorreta | Backup protegido com senha diferente | Informe a senha correta quando solicitado |

---

## 📘 Observações Importantes

- Compatível apenas com **backups do SGD (DW ou Nuvem)**.  
- Não altere a estrutura dos backups antes da execução.  
- Evite mover os arquivos durante a execução do script.  
- Recomenda-se rodar o script em ambiente de teste antes de produção.  
- Para evitar erros de caminho, mantenha os nomes dos backups curtos e sem espaços.

---

## 👨‍💻 Autor

**Sávio Morais**  
🔗 [github.com/savio-softnews/Log_Application](https://github.com/savio-softnews/Log_Application)

---

## 🪪 Licença

Este projeto é distribuído sob a **licença MIT**.  
Sinta-se livre para usar, modificar e redistribuir, mantendo os créditos originais.
