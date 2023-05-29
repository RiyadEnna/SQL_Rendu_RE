
--REQUÊTE SQL------------------------------------------------------------------------------

-- Q1) Afficher le nombre de commande totales supérieur à 50e que l’on a  dans le catalogue et la moyenne des prix des commandes

SELECT COUNT(*) AS nombre_commandes, AVG(p.price) AS moyenne_prix_commandes
FROM product AS p
INNER JOIN panier AS pa ON pa.id_produit = p.id
INNER JOIN commande AS c ON c.user_id = pa.id_user
WHERE p.price > 50;

--Q2 )Insérer 3 nouvelles promotion pour les produits de chez Apple ou tagué “Siri’ (en SQL)

--Q2-1) insertion de 3 promotion dès lors qu'un produit contien le titre Apple ou est tagué Siri (les taux des promotion sont randomisé)

INSERT INTO promotion (title, taux, enable)
SELECT CONCAT('Promotion Apple', n), FLOOR(RAND() * 100) + 1, 1
FROM (
  SELECT 1 AS n UNION ALL
  SELECT 2 AS n UNION ALL
  SELECT 3 AS n
) numbers
WHERE EXISTS (
  SELECT *
  FROM product AS p
	JOIN tag_produit tp ON p.id = tp.product_id
	JOIN tag t ON tp.tag_id = t.id
 	WHERE p.title LIKE '%Apple%' OR t.title LIKE '%Siri%'
)
LIMIT 3;

-- Autre version
-- Q2-2) insertion de 3 promotion dès lors qu'un produit contien la marque Apple ou est tagué Siri

/*
INSERT INTO promotion (title, taux, enable)
SELECT CONCAT('Promotion Apple', n), FLOOR(RAND() * 100) + 1, 1
FROM (
  SELECT 1 AS n UNION ALL
  SELECT 2 AS n UNION ALL
  SELECT 3 AS n
) numbers
WHERE EXISTS (
  SELECT *
  FROM product AS p
  LEFT JOIN brand_product bp ON p.id = bp.product_id
  LEFT JOIN brand b ON bp.brand_id = b.id
  LEFT JOIN tag_produit tp ON p.id = tp.product_id
  LEFT JOIN tag t ON tp.tag_id = t.id
  WHERE b.name ='Apple' OR t.title = 'Siri'
)
LIMIT 3;
*/

-- bonus cette requête créer une promotion  avec le nom des articles Apple ou tagué Siri suivi du mot promo
/*
INSERT INTO promotion (title, taux, enable)
SELECT CONCAT(p.title, ' Promotion ', ROW_NUMBER() OVER (ORDER BY p.id)), 10, 1
FROM product p
JOIN brand_product bp ON p.id = bp.product_id
JOIN brand b ON bp.brand_id = b.id
JOIN tag_produit tp ON p.id = tp.product_id
JOIN tag t ON tp.tag_id = t.id
WHERE b.name = 'Apple' OR t.title = 'Siri'
LIMIT 3; 
*/

--Q3 )Gérer les marques pour les produits (1 produit a 1 seul marque) avec title et localisation(ville) -->  Ctrl-f pour table brand
-- Table brand_product -->  Ctrl-f  pour table brand_product


CREATE TABLE brand (
  id INT PRIMARY KEY,
  name VARCHAR(100),
  location VARCHAR(100)
);
CREATE TABLE brand_product (
  product_id INT,
  brand_id INT,
  UNIQUE (product_id),
-- Ajout des clés étrangères
  FOREIGN KEY (product_id) REFERENCES product(id),
  FOREIGN KEY (brand_id) REFERENCES brand(id)
);
-- Ajout de la clé primaire composée
ALTER TABLE brand_product
ADD PRIMARY KEY (product_id, brand_id);
CREATE TABLE brand_ville (
  brand_id INT,
  ville_id INT,
  FOREIGN KEY (brand_id) REFERENCES brand (id),
  FOREIGN KEY (ville_id) REFERENCES ville (id)
);


--Q4 ) Afficher le nombre de marques par produits qui sont de Lyon

-- Version en utilisant la table ville_france_free

SELECT p.id AS product_id, p.title AS product_title, COUNT(bv.brand_id) AS brand_count
FROM product p
JOIN brand_product bp ON bp.product_id = p.id
JOIN brand b ON bp.brand_id = b.id
JOIN brand_ville bv ON bv.brand_id = b.id
WHERE bv.ville_id = (SELECT ville_id FROM villes_france_free AS vff WHERE ville_nom_reel = 'Lyon')
GROUP BY p.id, p.title;

--Version sans utiliser la table ville_france_free et où la localisation est directement dans la table brand. ()
/*
SELECT b.location ,p.id AS product_id, COUNT(bp.brand_id) AS brand_count
FROM product p
JOIN brand_product bp ON p.id = bp.product_id
JOIN brand b ON bp.brand_id = b.id
WHERE b.location = 'Lyon'
GROUP BY p.id;
*/

-- Q5 )Gérer les avis des utilisateurs sur les produits. Ctrl-f pour avis dans comments
--Versions où les avis sont dans les commentaires et ou un commentaire ne peut exister que si le produit et l'user existe

ALTER TABLE comments 
ADD CONSTRAINT fk_comments_user 
FOREIGN KEY (user_id) 
REFERENCES users (id) ON DELETE CASCADE, 
ADD CONSTRAINT fk_comments_product 
FOREIGN KEY (product_id) 
REFERENCES product (id) ON DELETE CASCADE; 
 ADD COLUMN avis INT CHECK (avis >= 0 AND avis <= 5);
 ADD CONSTRAINT uc_user_product UNIQUE (user_id, product_id);


--version alternative ou une table avis distinct de comments est créer . (je l'ai imaginer mais pas utiliser dans ma base)
/*
CREATE TABLE avis (
  user_id INT,
  product_id INT,
  comments_id INT,
  note INT CHECK (note >= 1 AND note <= 5),
  date_avis DATE,
  PRIMARY KEY (user_id, product_id, comments_id),
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE,
  FOREIGN KEY (comments_id) REFERENCES comments (id) ON DELETE CASCADE
);
*/

-- Q6 ) Supprimer tous les avis à 0 ou dont le contenu est inférieur à 3 mots -- > Ctrl-f pour aller vers table comments

DELETE FROM comments
WHERE avis = 0 OR LENGTH(TRIM(content)) - LENGTH(REPLACE(content, ' ', '')) + 1 < 3;

--Q7) Gérer les cartes de fidélité pour les utilisateurs (1 à 1). Ctrl-f pour aller vers table carte_fidelite

CREATE TABLE carte_fidelite (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT UNIQUE,
  numero_carte VARCHAR(20),
  points INT,
  ADD COLUMN nom_carte VARCHAR(255),
  date_creation DATE,
  FOREIGN KEY (user_id) REFERENCES users (id)
);


--Q8 )Afficher le nom des cartes de fidélité sur les 3 dernières commandes des utilisateurs

SELECT c.id AS commande_id, cf.nom_carte, u.nom AS user_nom, u.prenom AS user_prenom
FROM commande AS c
JOIN users AS u ON c.user_id = u.id
JOIN carte_fidelite AS cf ON u.id = cf.user_id
ORDER BY c.date_created DESC
LIMIT 3;

-- Q9 )Gérer les fournisseurs pour les produits. Attention 1 produit peut avoir plusieurs fournisseurs à la fois.

CREATE TABLE supplier (
  id INT PRIMARY KEY,
  name VARCHAR(255),
  address_id INT,
  product_id VARCHAR(255),
  FOREIGN KEY (address) REFERENCES ville_France_free (id)
);

CREATE TABLE supplier_product ( 
supplier_id INT, 
product_id INT, 
PRIMARY KEY (supplier_id, product_id), 
FOREIGN KEY (supplier_id) REFERENCES supplier (id), 
FOREIGN KEY (product_id) REFERENCES product (id) ); 


--Q10 )Afficher les fournisseurs qui fournissent le plus de produits depuis 2 ans ou plus.

SELECT s.id, s.name, COUNT(sp.product_id) AS total_products
FROM supplier s
JOIN supplier_product sp ON s.id = sp.supplier_id
JOIN product p ON sp.product_id = p.id
WHERE p.created <= NOW() - INTERVAL 2 YEAR
GROUP BY s.id, s.name
ORDER BY total_products DESC;

--Q11 )Gérer les administrateurs. Les administrateurs sont des super utilisateurs et on affichera les 2 derniers administrateurs créer. Parmis ces admins, il y aura 1 seul super-admin.
-- ctrl+f users

ALTER TABLE users
ADD COLUMN role ENUM('classique_user', 'admin', 'super-admin') NOT NULL DEFAULT 'classique_user';

SELECT *
FROM users
WHERE role = 'admin'
ORDER BY date_created DESC
LIMIT 2;

--Q12 )Gérer les adresses de facturation et livraison pour les utilisateurs avec les champs -- ctrl+f adresses_facturation

CREATE TABLE adresses_facturation (
 id INT PRIMARY KEY AUTO_INCREMENT,
 user_id INT,
 pays VARCHAR(50),
 region VARCHAR(50),
 code_postal VARCHAR(10),
 adresse VARCHAR(100),
 ville_id INT,
 latitude DECIMAL(9, 6),
 longitude DECIMAL(9, 6),
 FOREIGN KEY (user_id) REFERENCES users(id),
 FOREIGN KEY (ville_id) REFERENCES ville_france_free(ville_id),
 CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES users(id),
 CONSTRAINT fk_ville_id FOREIGN KEY (ville_id) REFERENCES ville_france_free(ville_id)
);



/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
