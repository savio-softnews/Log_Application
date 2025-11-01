# Aplicador de Log - Automação de Backup do SGD (Versão 2.0)

Automação em lote (`.bat`) desenvolvida para padronizar e agilizar o processo de **aplicação de logs em backups Domínio**, com suporte tanto para **backups Web (DW/Nuvem)** quanto para **backups Locais**.  
A versão 2.0 introduz rotinas específicas para cada tipo de backup, oferecendo mais flexibilidade, segurança e clareza na execução.

---

## 🧩 Requisitos

Antes de executar o script, certifique-se de que os seguintes programas estão instalados **nos caminhos padrões**:

- **7-Zip** instalado em: `C:\Program Files\7-Zip\7zG.exe`  
- **SQL Anywhere 17** instalado em: `C:\Program Files\SQL Anywhere 17\Bin64\dbeng17.exe`

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

3. Quando solicitado, informe o tipo de backup:
   ```
   Informe se o seu backup é de origem Web (DW/backup em nuvem) ou Local
   1 - Web
   2 - Local
   ```
   - Digite **1** para backups Web (DW/Nuvem)  
   - Digite **2** para backups Locais  

   3.1. Caso o tipo do backup seja **web**, o script perguntará:
      ```
      As senhas de descompactacao sao a senha padrao? (S/N)
      ```
      - Se **S**, o script usará a senha padrão. 
      - Se **N**, o usuário será solicitado a informar manualmente as senhas corretas para cada backup.

4. O script descompactará os arquivos, aplicará os logs e, ao final, será gerado o arquivo **`texto.txt`** contendo:
   - Tempos de execução  
   - Status das operações  
   - Caminhos utilizados  

---

## 📄 Saída Gerada

Após a execução, são criados:
- `texto.txt` → relatório detalhado com os tempos e resultados  
- `Logs` → pasta contendo registros de execução  
- `M` → pasta com arquivos temporários  


---

## 📘 Observações Importantes

- Compatível com **backups Domínio Web(DW/Nuvem) e Local**.  
- Não altere os nomes ou a estrutura dos arquivos `.dom`.  
- Evite espaços ou caracteres especiais nos nomes das pastas.  
- Recomenda-se testar antes em ambiente de homologação.

---

## 🧰 Troubleshooting (Solução de Problemas)

| Problema | Possível Causa | Solução |
|-----------|----------------|----------|
| Opção inválida ao escolher tipo de base | Valor incorreto informado | Execute novamente e informe `1` ou `2` |
| Erro ao descompactar backup | Caminho incorreto do 7-Zip | Verifique a instalação em `C:\Program Files\7-Zip\7zG.exe` |
| Banco não inicializa | Caminho incorreto do SQL Anywhere | Confirme a instalação em `C:\Program Files\SQL Anywhere 17\Bin64\dbeng17.exe` |
| Falha ao aplicar logs | Arquivos corrompidos ou senha incorreta | Baixe novamente o backup e confirme as senhas |
| Permissão negada | Execução sem privilégios | Execute o `.bat` como **Administrador** |

---

## 🧠 Passo a Passo Técnico Interno

A seguir, o funcionamento técnico da versão 2.0 do script.

### 1. Configuração inicial
- Define título da janela (`title Aplicador de Log`) e uso de UTF-8 (`chcp 65001`).
- Define os caminhos padrão de dependências:
  ```bat
  set "seteZipPath=C:\Program Files\7-Zip\7zG.exe"
  set "dbengPath=C:\Program Files\SQL Anywhere 17\Bin64\dbeng17.exe"
  ```
- Define variáveis de diretório (`%~dp0`, `M`, `Logs`).

### 2. Escolha do tipo de base
- Pergunta se o backup é **Web (DW/Nuvem)** ou **Local**:
  ```bat
  set /p tipo_base=Informe a sua resposta:
  if /I "!tipo_base!"=="1" (call :base_web)
  if /I "!tipo_base!"=="2" (call :base_local)
  ```
- Essa separação permite executar rotinas distintas dependendo do tipo de backup.

### 3. Rotina `:base_web`
- Descompacta os backups `.dom` usando **7-Zip** com a senha informada.  
- Aplica os logs automaticamente no banco SQL Anywhere restaurado.  
- Gera relatórios em `Logs` e o arquivo final `texto.txt`.

### 4. Rotina `:base_local`
- Executa os mesmos procedimentos, porém ajustados para backups locais.  
- Mantém as etapas de descompactação, restauração e aplicação de logs.

### 5. Registro e relatório final
- Cria o arquivo `texto.txt` com:
  - Duração de cada etapa (extração, aplicação de logs, finalização)
  - Status final da operação

### 6. Encerramento
- Exibe mensagem **"Processamento finalizado"**.
- Encerra o processo e mantém os logs disponíveis para consulta posterior.  

---

## 👨‍💻 Autor

**Sávio Morais**  
🔗 [LinkedIn](https://www.linkedin.com/in/savio-santana-de-morais/)   
🔗 [GitHub](https://github.com/Savio-S-Morais)

---

## 🪪 Licença

Distribuído sob a **licença MIT**.  
Permite uso, modificação e redistribuição, mantendo os créditos originais.
