create database LivrariaDB;

USE  LivrariaDB;

CREATE TABLE Livraria(
Nome NVARCHAR(40) NOT NULL,
ID INT PRIMARY KEY NOT NULL IDENTITY (1,1),
Gerente NVARCHAR (50) NOT NULL UNIQUE
);

CREATE TABLE Editora (
Nome NVARCHAR (50) NOT NULL,
Codigo INT PRIMARY KEY NOT NULL IDENTITY (1,1),
Gerente NVARCHAR (50) NOT NULL UNIQUE
);



CREATE TABLE Cliente (
ID INT NOT NULL PRIMARY KEY IDENTITY (1,1),
Nome NVARCHAR (50) NOT NULL
);

CREATE TABLE LIVRO(
ISBN NVARCHAR(20) NOT NULL PRIMARY KEY,
Nome NVARCHAR (100) NOT NULL,
Assunto NVARCHAR (50) NOT NULL,
EditoraCodigo INT NOT NULL,
Autor NVARCHAR (50) NOT NULL,
CONSTRAINT FK_Editora_Codigo FOREIGN KEY (EditoraCodigo) REFERENCES Editora(Codigo)
);


CREATE TABLE Estoque(
Quantidade INT NOT NULL,
LivroISBN NVARCHAR(20) NOT NULL,
LivrariaID INT NOT NULL,
CONSTRAINT FK_Livro_ISBN FOREIGN KEY (LivroISBN) REFERENCES Livro(ISBN),
CONSTRAINT FK_Livraria_ID FOREIGN KEY (LivrariaID) REFERENCES Livraria(ID)
);


CREATE TABLE ClientePF(
CPF NVARCHAR (14) NOT NULL,
Profissao NVARCHAR (60) NOT NULL,
ID INT NOT NULL,
CONSTRAINT FK_CLIENTE_ID FOREIGN KEY (ID) REFERENCES Cliente(ID)
);

CREATE TABLE ClientePJ (
CNPJ NVARCHAR (20) PRIMARY KEY NOT NULL,
Ramo NVARCHAR (40) NOT NULL,
IDCliente INT NOT NULL,
CONSTRAINT FK_ID_Cliente FOREIGN KEY (IDCliente) REFERENCES Cliente(ID)
);


CREATE TABLE Vendas (
IDVenda INT PRIMARY KEY NOT NULL IDENTITY (1,1),
Data DATE NOT NULL DEFAULT GETDATE(),
ISBNLivro NVARCHAR (20) NOT NULL,
ClienteID INT NOT NULL,
Quantidade INT NOT NULL,
Valor DECIMAL (10,2) NOT NULL,
CONSTRAINT FK_ClienteID_ID  FOREIGN KEY (ClienteID) REFERENCES Cliente(ID),
CONSTRAINT FK_ISBN_Livro FOREIGN KEY (ISBNLivro) REFERENCES LIVRO(ISBN)
);

CREATE TABLE ListaLivros( 
Cliente INT NOT NULL,
ISBNLivro NVARCHAR(20) NOT NULL,
CONSTRAINT FK_IDCliente_ID FOREIGN KEY (Cliente) REFERENCES Cliente(ID),
CONSTRAINT FK_ISBNLivro_ISBN FOREIGN KEY (ISBNLivro) REFERENCES LIVRO(ISBN)
); 

CREATE TABLE Compra( 
IDCompra INT NOT NULL IDENTITY (1,1),
Quantidade INT NOT NULL,
Data DATE NOT NULL DEFAULT GETDATE(),
CodigoEditora INT NOT NULL,
ISBN NVARCHAR (20) NOT NULL,
CONSTRAINT FK_CodigoEditora_Codigo FOREIGN KEY (CodigoEditora) REFERENCES Editora(Codigo),
CONSTRAINT FK_IDLivro_ISBN FOREIGN KEY (ISBN) REFERENCES LIVRO(ISBN),
);


CREATE TABLE Endereco(
Numero INT NOT NULL,
Logradouro NVARCHAR (100) NOT NULL,
Cidade NVARCHAR (50) NOT NULL,
Bairro NVARCHAR (30) NOT NULL,
ClienteID INT NULL,
EditoraCodigo INT NULL,
CONSTRAINT FK_IDDOCLIENTE FOREIGN KEY (ClienteID) REFERENCES Cliente(ID),
CONSTRAINT FK_ED_Codigo FOREIGN KEY (EditoraCodigo) REFERENCES Editora(Codigo),
CONSTRAINT CHK_EditoraouCliente CHECK (
(ClienteID IS NOT NULL AND EditoraCodigo IS NULL) 
OR
(ClienteID IS NULL AND EditoraCodigo IS NOT NULL) )
);

CREATE TABLE Telefone(
Numero NVARCHAR (11) NOT NULL,
DDD INT NOT NULL,
CodgoPais INT NOT NULL,
IDCliente INT NULL,
EditoraCodigo INT NULL,
CONSTRAINT FK_EditoraCodigo FOREIGN KEY (EditoraCodigo) REFERENCES Editora(Codigo),
CONSTRAINT FK_ID FOREIGN KEY (IDCliente) REFERENCES Cliente(ID),
CONSTRAINT CHK_IDouCodigo CHECK(
(IDCliente IS NOT NULL AND EditoraCodigo IS NULL)
OR
(IDCliente IS NULL AND EditoraCodigo IS NOT NULL)
)
);

EXEC sp_rename 'Telefone1','Telefone';



CREATE PROCEDURE sp_InserirCliente
@Nome NVARCHAR (50),
@CPF NVARCHAR (20),
@Profissao NVARCHAR (100)
AS 
BEGIN 
	DECLARE @ClienteID INT;
INSERT INTO Cliente(Nome)
VALUES(@Nome);
SET @CLIENTEID = SCOPE_IDENTITY()

INSERT INTO ClientePF(ID,CPF,Profissao)
VALUES (@ClienteID, @CPF, @Profissao);
END;



CREATE OR ALTER PROCEDURE sp_InserirClientePJ
    @Nome NVARCHAR(50),
    @CNPJ NVARCHAR(20),
    @Ramo NVARCHAR(100)
AS
BEGIN
    DECLARE @ClienteID INT;

    INSERT INTO Cliente(Nome)
    VALUES (@Nome);

    SET @ClienteID = SCOPE_IDENTITY();

    INSERT INTO ClientePJ(IDCliente, CNPJ, Ramo)
    VALUES (@ClienteID, @CNPJ, @Ramo);
END;

EXEC sp_InserirCliente 'Jose','124578511','DB';

SELECT * FROM Cliente;

DELETE FROM ClientePF;


DELETE FROM Cliente;


ALTER TABLE ClientePF
ADD CONSTRAINT UQ_ClientePF_CPF UNIQUE (CPF);


CREATE OR ALTER PROCEDURE sp_InserirCliente
@Nome NVARCHAR(50),
@CPF NVARCHAR(20),
@Profissao NVARCHAR(100)
AS
BEGIN
    
    IF EXISTS (SELECT 1 FROM ClientePF WHERE CPF = @CPF)
    BEGIN
        RAISERROR('CPF já cadastrado.', 16, 1);
        RETURN;
    END

    DECLARE @ClienteID INT;

    -- Insere na tabela Cliente
    INSERT INTO Cliente(Nome)
    VALUES (@Nome);

    -- Pega o ID gerado
    SET @ClienteID = SCOPE_IDENTITY();

    -- Insere na ClientePF
    INSERT INTO ClientePF(ID, CPF, Profissao)
    VALUES (@ClienteID, @CPF, @Profissao );
    
    
    
    WITH ClientesComLinha AS (
    SELECT 
        ID,
        Nome,
        ROW_NUMBER() OVER (PARTITION BY Nome ORDER BY ID) AS Linha
    FROM Cliente
)
DELETE FROM Cliente
WHERE ID IN (
    SELECT ID FROM ClientesComLinha WHERE Linha > 1
);
 END;
    
    
    CREATE OR ALTER PROCEDURE sp_InserirClientePJ
    @Nome NVARCHAR(50),
    @CNPJ NVARCHAR(20),
    @Ramo NVARCHAR(100)
AS
BEGIN
    -- Verifica se o CNPJ já está cadastrado
    IF EXISTS (SELECT 1 FROM ClientePJ WHERE CNPJ = @CNPJ)
    BEGIN
        RAISERROR('CNPJ já cadastrado.', 16, 1);
        RETURN;
    END

    DECLARE @ClienteID INT;

    -- Insere o nome na tabela Cliente
    INSERT INTO Cliente(Nome)
    VALUES (@Nome);

    -- Recupera o ID do cliente recém-inserido
    SET @ClienteID = SCOPE_IDENTITY();

    -- Insere os dados na tabela ClientePJ
    INSERT INTO ClientePJ(IDCliente, CNPJ, Ramo)
    VALUES (@ClienteID, @CNPJ, @Ramo );
END;


alter table Compra ADD IDLivraria INT;

alter table Compra 
add constraint FK_CompraLivraria foreign key (IDLivraria) REFERENCES Livraria(ID);