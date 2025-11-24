DROP DATABASE IF EXISTS techmarica_producao;
CREATE DATABASE techmarica_producao;
USE techmarica_producao;

CREATE TABLE IF NOT EXISTS funcionarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(14) UNIQUE,
    email VARCHAR(150) UNIQUE,
    area VARCHAR(50) NOT NULL,
    ativo TINYINT(1) NOT NULL DEFAULT 1,
    data_admissao DATE,
    CONSTRAINT chk_area CHECK (area <> '')
);

CREATE TABLE IF NOT EXISTS maquinas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo_maquina VARCHAR(30) NOT NULL UNIQUE,
    nome VARCHAR(100) NOT NULL,
    localizacao VARCHAR(100),
    status VARCHAR(20) NOT NULL DEFAULT 'OPERACIONAL'
);

CREATE TABLE IF NOT EXISTS produtos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo_interno VARCHAR(30) NOT NULL UNIQUE,
    nome VARCHAR(150) NOT NULL,
    responsavel_tecnico INT NOT NULL,
    custo_producao DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    data_catalogo DATE NOT NULL DEFAULT (CURRENT_DATE()),
    descricao TEXT,
    CONSTRAINT fk_prod_resp FOREIGN KEY (responsavel_tecnico) REFERENCES funcionarios(id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS ordens_producao (
    id INT AUTO_INCREMENT PRIMARY KEY,
    produto_id INT NOT NULL,
    maquina_id INT NOT NULL,
    funcionario_autorizou INT NOT NULL,
    lote VARCHAR(50) NULL,
    quantidade INT NOT NULL DEFAULT 1,
    data_inicio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_conclusao DATETIME NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'EM PRODUÇÃO',
    observacoes TEXT,
    CONSTRAINT fk_ord_prod_prod FOREIGN KEY (produto_id) REFERENCES produtos(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ord_prod_maq FOREIGN KEY (maquina_id) REFERENCES maquinas(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ord_prod_func FOREIGN KEY (funcionario_autorizou) REFERENCES funcionarios(id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS log_ordens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ordem_id INT,
    acao VARCHAR(50),
    descricao TEXT,
    data_log TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_log_ord FOREIGN KEY (ordem_id) REFERENCES ordens_producao(id) ON DELETE SET NULL
);

CREATE INDEX idx_ordens_produto ON ordens_producao(produto_id);
CREATE INDEX idx_produtos_resp ON produtos(responsavel_tecnico);

INSERT INTO funcionarios(nome, cpf, email, area, ativo, data_admissao) VALUES
('Ana Souza', '123.456.789-00', 'ana.souza@techmarica.com', 'Engenharia', 1, '2020-03-10'),
('Bruno Lima', '111.222.333-44', 'bruno.lima@techmarica.com', 'Produção', 1, '2019-07-01'),
('Carla Mendes', '222.333.444-55', 'carla.mendes@techmarica.com', 'Qualidade', 1, '2021-01-15'),
('Diego Rocha', '333.444.555-66', 'diego.rocha@techmarica.com', 'Manutenção', 0, '2017-09-20'),
('Eduarda Nunes', '444.555.666-77', 'eduarda.nunes@techmarica.com', 'Pesquisa', 1, '2022-05-04');

INSERT INTO maquinas(codigo_maquina, nome, localizacao, status) VALUES
('MQ-PL-01', 'Linha de Montagem A', 'Pavilhão 1', 'OPERACIONAL'),
('MQ-TEST-02', 'Banco de Teste B', 'Pavilhão 2', 'OPERACIONAL'),
('MQ-REF-03', 'Estação de Reflow', 'Pavilhão 1', 'MANUTENCAO');

INSERT INTO produtos(codigo_interno, nome, responsavel_tecnico, custo_producao, data_catalogo, descricao) VALUES
('TMX-1000', 'Sensor de Temperatura TMX-1000', 1, 42.50, '2022-02-01', 'Sensor digital para HVAC'),
('PLT-220', 'Placa de Circuito PLT-220', 2, 85.00, '2021-06-15', 'Placa principal para controlador'),
('MDL-900', 'Módulo Inteligente MDL-900', 5, 150.00, '2023-03-10', 'Módulo com Wi-Fi e MCU'),
('SEN-50', 'Sensor de Proximidade SEN-50', 1, 12.00, '2020-11-20', 'Sensor para automação'),
('ALM-11', 'Alimentador ALM-11', 3, 30.00, '2019-08-05', 'Fonte/regulador para placas');

-- ordens de produção (vários cenários)
INSERT INTO ordens_producao(produto_id, maquina_id, funcionario_autorizou, lote, quantidade, data_inicio, data_conclusao, status, observacoes)
VALUES (1, 1, 2, 'L20251101A', 100, '2025-11-01 08:00:00', '2025-11-03 14:30:00', 'FINALIZADA', 'Produção normal');

INSERT INTO ordens_producao(produto_id, maquina_id, funcionario_autorizou, lote, quantidade, data_inicio, status, observacoes)
VALUES (2, 2, 2, 'L20251110B', 50, '2025-11-10 09:00:00', 'EM PRODUÇÃO', 'Teste de lotes');

INSERT INTO ordens_producao(produto_id, maquina_id, funcionario_autorizou, lote, quantidade, data_inicio, data_conclusao, status, observacoes)
VALUES (3, 1, 5, 'L20251015C', 20, '2025-10-15 07:30:00', '2025-10-16 10:00:00', 'CANCELADA', 'Problema de peça');

INSERT INTO ordens_producao(produto_id, maquina_id, funcionario_autorizou, lote, quantidade, data_inicio, status)
VALUES (4, 1, 2, 'L20251115D', 200, '2025-11-15 07:00:00', 'EM PRODUÇÃO');

INSERT INTO ordens_producao(produto_id, maquina_id, funcionario_autorizou, lote, quantidade, data_inicio)
VALUES (5, 2, 1, 'L20251118E', 75, '2025-11-18 13:15:00');

DROP VIEW IF EXISTS vw_producao_consolidada;
CREATE VIEW vw_producao_consolidada AS
SELECT
    o.id AS ordem_id,
    o.lote,
    o.quantidade,
    o.data_inicio,
    o.data_conclusao,
    o.status,
    p.id AS produto_id,
    p.codigo_interno AS produto_codigo,
    p.nome AS produto_nome,
    p.custo_producao,
    m.id AS maquina_id,
    m.codigo_maquina,
    m.nome AS maquina_nome,
    f.id AS funcionario_id,
    f.nome AS funcionario_autorizou,
    f.area AS area_autorizacao
FROM ordens_producao o
JOIN produtos p ON p.id = o.produto_id
JOIN maquinas m ON m.id = o.maquina_id
JOIN funcionarios f ON f.id = o.funcionario_autorizou;

DELIMITER $$
DROP PROCEDURE IF EXISTS sp_registrar_ordem;
CREATE PROCEDURE sp_registrar_ordem(
    IN p_produto INT,
    IN p_funcionario_autorizou INT,
    IN p_maquina INT,
    IN p_lote VARCHAR(50),
    IN p_quantidade INT
)
BEGIN
    INSERT INTO ordens_producao(produto_id, maquina_id, funcionario_autorizou, lote, quantidade, data_inicio, status)
    VALUES (p_produto, p_maquina, p_funcionario_autorizou, p_lote, p_quantidade, NOW(), 'EM PRODUÇÃO');

    SELECT CONCAT('Ordem registrada com sucesso. id = ', LAST_INSERT_ID()) AS mensagem;
END $$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS trg_ordens_finaliza;
CREATE TRIGGER trg_ordens_finaliza
BEFORE UPDATE ON ordens_producao
FOR EACH ROW
BEGIN
    IF OLD.data_conclusao IS NULL AND NEW.data_conclusao IS NOT NULL THEN
        SET NEW.status = 'FINALIZADA';
    END IF;
END $$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS trg_log_ordem_update;
CREATE TRIGGER trg_log_ordem_update
AFTER UPDATE ON ordens_producao
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status THEN
        INSERT INTO log_ordens(ordem_id, acao, descricao)
        VALUES (NEW.id, 'STATUS_ALTERADO', CONCAT('Status de ', OLD.status, ' -> ', NEW.status));
    END IF;
END $$
DELIMITER ;

SELECT
    o.id AS ordem_id,
    o.lote,
    p.codigo_interno,
    p.nome AS produto,
    m.nome AS maquina,
    f.nome AS autorizado_por,
    o.quantidade,
    o.data_inicio,
    o.data_conclusao,
    o.status
FROM ordens_producao o
JOIN produtos p ON p.id = o.produto_id
JOIN maquinas m ON m.id = o.maquina_id
JOIN funcionarios f ON f.id = o.funcionario_autorizou
ORDER BY o.data_inicio DESC;

SELECT id, nome, area, data_admissao
FROM funcionarios
WHERE ativo = 0;

SELECT f.nome AS responsavel, COUNT(p.id) AS total_produtos
FROM funcionarios f
LEFT JOIN produtos p ON p.responsavel_tecnico = f.id
GROUP BY f.id, f.nome
ORDER BY total_produtos DESC;

SELECT id, codigo_interno, nome
FROM produtos
WHERE nome LIKE 'S%';

SELECT id, nome, data_catalogo,
       TIMESTAMPDIFF(YEAR, data_catalogo, CURDATE()) AS idade_anos
FROM produtos
ORDER BY idade_anos DESC;

SELECT p.id, p.nome, IFNULL(SUM(o.quantidade),0) AS total_produzido
FROM produtos p
LEFT JOIN ordens_producao o ON o.produto_id = p.id AND o.status = 'FINALIZADA'
GROUP BY p.id, p.nome
ORDER BY total_produzido DESC;

SELECT m.nome AS maquina, COUNT(o.id) AS ordens_em_producao
FROM maquinas m
LEFT JOIN ordens_producao o ON o.maquina_id = m.id AND o.status = 'EM PRODUÇÃO'
GROUP BY m.id, m.nome;

SELECT id, UPPER(nome) AS nome_maiusculo FROM produtos;

SELECT * FROM ordens_producao
WHERE MONTH(data_inicio) = MONTH(CURDATE()) AND YEAR(data_inicio) = YEAR(CURDATE());

SELECT f.nome AS responsavel_tecnico,
       COUNT(DISTINCT p.id) AS qtd_produtos,
       IFNULL(SUM(CASE WHEN o.status = 'FINALIZADA' THEN o.quantidade ELSE 0 END),0) AS total_finalizado
FROM funcionarios f
LEFT JOIN produtos p ON p.responsavel_tecnico = f.id
LEFT JOIN ordens_producao o ON o.produto_id = p.id
GROUP BY f.id, f.nome
ORDER BY total_finalizado DESC;