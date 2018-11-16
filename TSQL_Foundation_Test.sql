172.16.77.15
sa 

SELECT *
FROM Sales.Order


SELECT　TOP(1)WITH TIES orderid,empid,orderdate
FROM Sales.Orders
WHERE orderid BETWEEN 10300 AND 10400
ORDER BY orderdate;

10300	2	2013-09-09
10301	8	2013-09-09

SELECT empid,firstname,lastname
FROM HR.Employees
WHERE lastname LIKE N'D%';

1	Sara	Davis
9	Patricia	Doyle

SELECT orderid,empid,orderdate
FROM Sales.Orders
WHERE orderdate >='20080101'
	AND empid IN(1,3,5);

10248	5	2013-07-04
10251	3	2013-07-08
10253	3	2013-07-10
10254	5	2013-07-11
10256	3	2013-07-15
10258	1	2013-07-17
10266	3	2013-07-26
10269	5	2013-07-31
10270	1	2013-08-01
10273	3	2013-08-05
....

SELECT orderid,productid,qty,unitprice,discount,
	qty*unitprice*(1-discount) AS val
FROM Sales.OrderDetails

SELECT orderid,custid,empid,orderdate
FROM Sales.Orders
WHERE 
	custid =1
	AND empid IN(1,3,5)
	OR custid = 85
	AND empid IN(2,4,6

10274	85	6	2013-08-06
10295	85	2	2013-09-02
10737	85	2	2014-11-11
10835	1	1	2015-01-15
10952	1	1	2015-03-16
11011	1	3	2015-04-09

SELECT orderid ,custid,val,
	CASE
		WHEN val<1000.00 THEN 'Less than 1000'
		WHEN val BETWEEN 1000.00 AND 3000.00 THEN 'Between 1000 and 3000'
		WHEN val> 3000.00 THEN 'More than 3000'
		ELSE 'UNKNOWN'
	END AS valuecategory
FROM Sales.OrderValues

10248	85	440.00	Less than 1000
10249	79	1778.60	Between 1000 and 3000
10250	34	1478.40	Between 1000 and 3000
10251	84	654.06	Less than 1000
10252	76	3597.90	More than 3000
10253	34	1444.80	Between 1000 and 3000
10254	14	556.62	Less than 1000

SELECT custid,country,region,city
FROM Sales.Customers
WHERE region=N'WA';

43	USA	WA	Walla Walla
82	USA	WA	Kirkland
89	USA	WA	Seattle

SELECT custid,country,region,city
FROM Sales.Customers
WHERE region<>N'WA';

SELECT custid,country,region,city
FROM Sales.Customers
WHERE region IS NULL;
1	Germany	NULL	Berlin
2	Mexico	NULL	México D.F.
3	Mexico	NULL	México D.F.
4	UK	NULL	London
5	Sweden	NULL	Luleå
6	Germany	NULL	Mannheim
7	France	NULL	Strasbourg

SELECT custid,country,region,city
FROM Sales.Customers
WHERE region<> N'WA'
	OR region IS NULL;

1	Germany	NULL	Berlin
2	Mexico	NULL	México D.F.
3	Mexico	NULL	México D.F.
4	UK	NULL	London
5	Sweden	NULL	Luleå
6	Germany	NULL	Mannheim
7	France	NULL	Strasbourg
8	Spain	NULL	Madrid
9	France	NULL	Marseille
10	Canada	BC	Tsawassen
11	UK	NULL	London

区分大小写 COLLATE Chinese_PRC_CS_AS
SELECT empid,firstname,lastname
FROM HR.Employees
WHERE lastname = N'davis';

SELECT empid,firstname,lastname
FROM HR.Employees
WHERE lastname COLLATE Chinese_PRC_CS_AS = N'davis'

SELECT empid,firstname+N' '+lastname AS fullname
FROM HR.Employees;
1	Sara Davis
2	Don Funk
3	Judy Lew
4	Yael Peled
5	Sven Mortensen
6	Paul Suurs
7	Russell King
8	Maria Cameron
9	Patricia Doyle

SELECT custid,country,region,city,
	country +N','+region +N','+city AS location
FROM Sales.Customers;

1	Germany	NULL	Berlin	NULL
2	Mexico	NULL	México D.F.	NULL
3	Mexico	NULL	México D.F.	NULL
4	UK	NULL	London	NULL
5	Sweden	NULL	Luleå	NULL
6	Germany	NULL	Mannheim	NULL
7	France	NULL	Strasbourg	NULL
8	Spain	NULL	Madrid	NULL
9	France	NULL	Marseille	NULL
10	Canada	BC	Tsawassen	Canada,BC,Tsawassen
11	UK	NULL	London	NULL

空字符串的拼接 country +COALESCE(N','+region,N'' )+N','+city AS location
SELECT custid,country,region,city,
	country +COALESCE(N','+region,N'' )+N','+city AS location
FROM Sales.Customers;
1	Germany	NULL	Berlin	Germany,Berlin
2	Mexico	NULL	México D.F.	Mexico,México D.F.
3	Mexico	NULL	México D.F.	Mexico,México D.F.
4	UK	NULL	London	UK,London
5	Sweden	NULL	Luleå	Sweden,Luleå
6	Germany	NULL	Mannheim	Germany,Mannheim
7	France	NULL	Strasbourg	France,Strasbourg
8	Spain	NULL	Madrid	Spain,Madrid
9	France	NULL	Marseille	France,Marseille
10	Canada	BC	Tsawassen	Canada,BC,Tsawassen
11	UK	NULL	London	UK,London

使用CONCAT('a','b','c'),将NULL赋值为空字符串
SELECT custid,country,region,city,
	CONCAT(country,N','+region,N','+city) AS location
	FROM Sales.Customers;
1	Germany	NULL	Berlin	Germany,Berlin
2	Mexico	NULL	México D.F.	Mexico,México D.F.
3	Mexico	NULL	México D.F.	Mexico,México D.F.
4	UK	NULL	London	UK,London
5	Sweden	NULL	Luleå	Sweden,Luleå
6	Germany	NULL	Mannheim	Germany,Mannheim
7	France	NULL	Strasbourg	France,Strasbourg
8	Spain	NULL	Madrid	Spain,Madrid
9	France	NULL	Marseille	France,Marseille
10	Canada	BC	Tsawassen	Canada,BC,Tsawassen
11	UK	NULL	London	UK,London

SELECT SUBSTRING('hechuwei',3,8);
chuwei

SELECT RIGHT('hechuwei',6);
chuwei

LEN和DATALENGTH函数
SELECT LEN(N'hechuwei');
8
SELECT DATALENGTH(N'hechuwei');
16
SELECT LEN(N'hechuwei    ');
8
SELECT DATALENGTH(N'hechuwei    ');
24
注意：LEN 和DATALENGTH之间的一个区别是前者删除尾随空格。

CHARINDEX 返回子字符串在字符串中第一次出现的位置。
CHARINDEX(substring,string[,start_POS])
SELECT CHARINDEX('chu','hechuwei');
3

PARTINDEX函数返回模式在字符串中第一次出现的位置。
PATINDEX(pattern,string)
SELECT PATINDEX('%[0-9]%','abcd123efgh');
5

REPLACE (string,substring1,substring2)
SELECT REPLACE('1-a 2-b','-',':');
1:a 2:b

SELECT empid,lastname,
LEN(lastname)-LEN(REPLACE(lastname,'e',''))
AS numoccur
FROM HR.Employees;
8	Cameron	1
1	Davis	0
9	Doyle	1
2	Funk	0
7	King	0
3	Lew	1
5	Mortensen	2
4	Peled	2
6	Suurs	0

REPLACE函数按照指定的次数重复一个字符串
SELECT REPLICATE('abc',3);
abcabcabc

STUFF函数
从字符串中移除指定数量的字符，并插入一个替代的新子字符串
STUFF(string,pos,delete_length,insertstring)
SELECT STUFF('xyz',2,0,'abc');
xabcyz
SELECT STUFF('xyz',2,1,'abc');
xabcz

UPPER 和 LOWER 函数
SELECT UPPER('HeChuWei');
HECHUWEI
SELECT LOWER('HeChuWei');
hechuwei

RTRIM 和 LTRIM
分别返回删除尾随或前导空格后的输入字符串
SELECT RTRIM(LTRIM('  abc  '));
abc

FORMAT函数
将输入值格式化成一个字符串
FORMAT(input,format_string,culture)
SELECT FORMAT(175,'00000000');
00000175

LIKE谓词 
%:多个字符
_:单个字符
[<list of characters>]
[characters - characters]
[^<characters list of Range>]
ESCAPE ：指定一个确信没有出现在数据中的字符作为转义字符，放在要查找字符的前面，并在模式后面指定跟随有转义字符的ESCAPE关键字。
eg: coll LIKE '&!_%'ESCAPE '!'

2.7 使用日期和时间数据

SELECT orderid,custid,empid,orderdate
FROM Sales.Orders
WHERE orderdate = CAST('20140212' AS DATETIME);
10443	66	8	2014-02-12
10444	5	3	2014-02-12


推荐使用与语言无关的日期和时间数据类型格式
DATETIME SMALLDATETIME DATE DATETIME2 DATETIMEOFFSET TIME

筛选日期范围
SELECT orderid,custid,empid,orderdate
FROM Sales.Orders
WHERE YEAR(orderdate) = 2014;

要获得高效使用索引的潜力，需要像修改谓词，不要在筛选列上执行操作。
SELECT orderid ,custid,empid,orderdate
FROM Sales.Orders
WHERE orderdate >= '20140101' AND orderdate<'20150101';

2.7.5 日期和时间函数
1. 当前日期和时间
SELECT 
	GETDATE() AS [GETDATE],
	CURRENT_TIMESTAMP AS [CURRENT_TIMESTAMP],
	GETUTCDATE() AS [GETUTCDATE],
	SYSDATETIME() AS [SYSDATETIME],
	SYSUTCDATETIME() AS [SYSUTCDATETIME],
	SYSDATETIMEOFFSET() AS [SYSDATETIMEOFFSET];
2018-10-08 14:34:11.517	
2018-10-08 14:34:11.517	
2018-10-08 06:34:11.517	
2018-10-08 14:34:11.5184585	
2018-10-08 06:34:11.5184585	
2018-10-08 14:34:11.5184585 +08:00

上述sql没有返回当前系统日期或系统时间的函数。不过可以向下面转换
SELECT
	CAST(SYSDATETIME() AS DATE) AS [current_data],
	CAST(SYSDATETIME() AS TIME) AS [current_time];
2018-10-08	14:41:19.2824661

2. CAST CONVERT 和 PAERSE 及其TRY_对应函数

TRY_ :每个前缀"TRY_"的函数接受与其对应函数相同的输入，执行相同的操作；
不同的是，如果输入不能转换伟目标类型，函数返回NULL，而不是查询故障。
SELECT CAST('20181008' AS DATE);
2018-10-08
SELECT CAST(SYSDATETIME() AS DATE);
2018-10-08
SELECT CAST(SYSDATETIME() AS time);
14:51:32.7653998

SELECT CAST('20182008' AS DATE);
error
SELECT TRY_CAST('20182008' AS DATE);
NULL

SELECT CONVERT(CHAR(8),CURRENT_TIMESTAMP,112);
20181008

SELECT PARSE('02/12/2007' AS DATETIME USING 'en-US');
2007-02-12 00:00:00.000

3. SWITCHOFFSET 函数
将输入的DATETIMEOFFSET值调整为指定的时区

4. TODATETIMEOFFSET函数
设置输入日期和时间值的时区偏移量

5. DATEADD函数
允许为指定的日期部分增加一个指定单位数量到驶入的日期和时间值中。
part 的有效输入值year quarter month dayofyear day week weekday hour minute second millisecond microsecond nanosecond
也可以缩写 yy 代替 year

SELECT DATEADD (YEAR,1,'20181008');
2019-10-08 00:00:00.000

6. DATEDIFF
两个日期和日期之间在指定日期部分的差异
SELECT DATEDIFF (day,'20080212','20090212') +'天' AS DIFF;
366
SELECT CAST(DATEDIFF (day,'20080212','20090212') AS varchar)+'天' AS DIFF;
366天

7. DATEPART
SELECT DATEPART(month,'20080212');

ISDATE(string)

EOMONTH 
接受一个日期和时间，返回相应的月末午夜日期。
SELECT orderid, orderdate,custid,empid
FROM Sales.Orders
WHERE orderdate = EOMONTH(orderdate);
10269	2013-07-31	89	5
10317	2013-09-30	48	6
10343	2013-10-31	44	4
10399	2013-12-31	83	8
10432	2014-01-31	75	3
10460	2014-02-28	24	8
10461	2014-02-28	46	1

2.10 练习

SELECT　* 
FROM  Sales.Orders
WHERE year(orderdate) = 2014
	AND MONTH(orderdate) = 6;

WHERE orderdate>='20140601'AND orderdate<'20140701';

SELECT orderid ,orderdate,custid,empid
FROM Sales.Orders
WHERE orderdate = EOMONTH(orderdate);

SELECT empid, firstname,lastname
FROM HR.Employees
WHERE firstname LIKE '%a%a%';

SELECT orderid,(quantity*unitprice)AS totalvalue
FROM Sales.OrderDetails
WHERE quantity*unitprice AS totalvalue >=10000
ORDER BY totalvalue;

SELECT orderid,(qty*unitprice)AS totalvalue
FROM Sales.OrderDetails
WHERE qty*unitprice  >=10000
ORDER BY totalvalue;

SELECT orderid ,SUM (qty* unitprice) AS totalvalue
FROM Sales.OrderDetails
GROUP BY orderid 
HAVING SUM(qty*unitprice) > 10000
ORDER BY totalvalue DESC;

2014年平均运费最高的三个国家
SELECT  TOP(3)shipcountry,avg(freight) AS avgfreight
FROM Sales.Orders
WHERE orderdate>='20140101' AND orderdate<'20150101'
GROUP BY shipcountry
ORDER BY avgfreight DESC;

Austria	178.3642
Switzerland	117.1775
Sweden	105.16

SELECT custid,orderdate,orderid,
	ROW_NUMBER() OVER(PARTITION BY custid ORDER BY orderdate,orderid) AS rownum 
FROM Sales.Orders
ORDER BY orderid,rownum ;

85	2013-07-04	10248	1
79	2013-07-05	10249	1
34	2013-07-08	10250	1
84	2013-07-08	10251	1
76	2013-07-09	10252	1
34	2013-07-10	10253	2
14	2013-07-11	10254	1
68	2013-07-12	10255	1
88	2013-07-15	10256	1
35	2013-07-16	10257	1
20	2013-07-17	10258	1
13	2013-07-18	10259	1
56	2013-07-19	10260	1
61	2013-07-19	10261	1
65	2013-07-22	10262	1


SELECT empid, firstname,lastname,titleofcourtesy,
CASE 
	WHEN titleofcourtesy IN('MS.','Mrs.') THEN 'Female'
	WHEN titleofcourtesy = 'Mr.'		THEN 'Male'
	ELSE								'Unknown'
	END AS gender
FROM HR.Employees

1	Sara	Davis	Ms.	Female
2	Don	Funk	Dr.	Unknown
3	Judy	Lew	Ms.	Female
4	Yael	Peled	Mrs.	Female
5	Sven	Mortensen	Mr.	Male
6	Paul	Suurs	Mr.	Male
7	Russell	King	Mr.	Male
8	Maria	Cameron	Ms.	Female
9	Patricia	Doyle	Ms.	Female

排序，且把NULL　放到后面
SELECT custid,region
FROM Sales.Customers
ORDER BY  CASE WHEN region IS NULL THEN 1 ELSE 0 END,region;


第三章　联接
SELECT H.empid ,H.firstname,H.lastname,D.n  
FROM HR.Employees AS H
	CROSS JOIN  dbo.Nums AS D 
WHERE D.n <=5
ORDER BY D.n;

SELECT C.custid,COUNT(DISTINCT O.orderid) AS numorders,SUM(OD.qty) AS totalaty 
FROM Sales.Customers AS C
	JOIN Sales.Orders AS O
	ON O.custid = C.custid
	JOIN Sales.OrderDetails AS OD
	ON OD.orderid = O.orderid
WHERE C.country = N'USA'
GROUP BY C.custid;

32	11	345
36	5	122
43	2	20
45	4	181
48	8	134
55	10	603
65	18	1383
71	31	4958
75	9	327
77	4	46
78	3	59
82	3	89
89	14	1063

SELECT C.custid,C.companyname,O.orderid,O.orderdate
FROM Sales.Customers AS C
	LEFT JOIN Sales.Orders AS O
	ON C.custid = O.custid;


第四章　子查询
SELECT　custid ,companyname
FROM Sales.Customers AS C
WHERE country = N'Spain'
	AND NOT EXISTS
	(SELECT *FROM Sales.Orders AS O
	WHERE O.custid = C.custid);



第五章 表表达式

5.1 派生表

注意：什么情况下必须要用 GROUP　BY 
DECLARE @empid AS INT =3;

SELECT orderyear,COUNT(DISTINCT custid) AS numcusts
FROM (SELECT YEAR(orderdate)AS orderyear,custid
		FROM Sales.Orders
		WHERE empid = @empid)AS D
GROUP BY orderyear;

SELECT YEAR(orderdate) AS orderyear,COUNT(DISTINCT custid) AS numcusts
FROM Sales.Orders
GROUP BY YEAR(orderdate)
HAVING COUNT(DISTINCT custid) >70;

SELECT Cur.orderyear,
	Cur.numcusts AS curnumcusts,Prv.numcusts AS prvnumcusts,
	Cur.numcusts - Prv.numcusts AS growth
	FROM (SELECT YEAR(orderdate) AS orderyear,
					COUNT (DISTINCT custid)AS numcusts
		FROM Sales.Orders
		GROUP BY YEAR(orderdate))AS Cur
		LEFT OUTER JOIN 
			(SELECT YEAR(orderdate) AS orderyear,
					COUNT (DISTINCT custid)AS numcusts
		FROM Sales.Orders
		GROUP BY YEAR(orderdate))AS Prv
		ON Cur.orderyear = Prv.orderyear+1;

2013	67	NULL	NULL
2014	86	67	19
2015	81	86	-5


5.2 公用表表达式

WITH YearlyCount AS 
(
	SELECT YEAR(orderdate) AS orderyear,
	COUNT (DISTINCT custid ) AS numcusts
	FROM Sales.Orders
	GROUP BY YEAR(orderdate)
)

SELECT Cur.orderyear,
	Cur.numcusts AS curnumcusts,Prv.numcusts AS prvnumcusts,
	Cur.numcusts - Prv.numcusts AS growth
FROM YearlyCount AS　Cur
LEFT　JOIN　YearlyCount AS Prv 
ON Cur.orderyear = Prv.orderyear+1;


2013	67	NULL	NULL
2014	86	67	19
2015	81	86	-5


5.5 APPLY 
当希望将一个表表达式应用到源表的每一行，并将所有结果集组合到一个结果表中时，使用APPLY运算符。
SELECT  C.custid,A.orderid,A.orderdate
FROM Sales.Customers AS C
	CROSS APPLY 
	(SELECT orderid,empid,orderdate,requirddate
		FROM Sales.Orders AS O
		WHERE O.custid = C.custid
		ORDER BY orderdate DESC, orderid DESC
		OFFESET 0 ROWS FETCH FIRST 3 ROWS ONLY ) AS A;

练习：
1-1 

SELECT empid , MAX(orderdate) AS maxorderdate
FROM  Sales.Orders
GROUP BY empid;


SELECT　O.empid ,O.orderdate,O.orderid,O.custid
FROM Sales.Orders AS O
JOIN (SELECT empid , MAX(orderdate) AS maxorderdate
FROM  Sales.Orders
GROUP BY empid) AS D
ON O.empid = D.empid 
AND O.orderdate = D.maxorderdatte;

9	2015-04-29	11058	6
8	2015-05-06	11075	68
7	2015-05-06	11074	73
6	2015-04-23	11045	10
5	2015-04-22	11043	74
4	2015-05-06	11076	9
3	2015-04-30	11063	37
2	2015-05-05	11073	58
2	2015-05-05	11070	44
1	2015-05-06	11077	65

第六章 集合运算符

6.1 UNION 运算符
UNION　ALL ：所有条目
UNION  : 去除重复元素

6.2 INTERSECT 运算符

INTERSECT 只返回一个
所以用 ROW_NUMBER函数应用 返回多个交集


SELECT 
	ROW_NUMBER()
		OVER (PARTITION BY country,region,city
				ORDER BY (SELECT O)) AS rownum,
		country,region,city
FROM HR.Employees

INTERSECT

SELECT 
	ROW_NUMBER()
		OVER (PARTITION BY country,region,city
				ORDER BY (SELECT O)) AS rownum,
		country,region,city
FROM Sales.Customers;


6.3 EXCEPT运算符



第七章 查询

7.1 开窗函数

SELECT　empid,ordermonth,val,
	SUM(val) OVER(PARTITION BY empid 
				ORDER BY ordermonth
				ROWS BETWEEN UNBOUNDED PRECEDING
					AND CURRENT ROW )AS runval
FROM Sales.EmpOrders;

1	2013-07-01	1614.88	1614.88
1	2013-08-01	5555.90	7170.78
1	2013-09-01	6651.00	13821.78
1	2013-10-01	3933.18	17754.96
1	2013-11-01	9562.65	27317.61
1	2013-12-01	8446.91	35764.52
1	2014-01-01	7331.60	43096.12
1	2015-05-01	6517.47	191437.17
2	2013-07-01	1176.00	1176.00
2	2013-08-01	1814.00	2990.00
2	2013-09-01	2950.80	5940.80


7.1.1 排名开窗函数

SELECT　orderid,custid,val,
	ROW_NUMBER() OVER(ORDER BY val)AS rownum,
	RANK ()      OVER(ORDER BY val)AS rank,
	DENSE_RANK() OVER(ORDER BY val)AS dense_rank,
	NTILE(800)   OVER(ORDER BY val)AS ntile
FROM Sales.OrderValues
ORDER BY val;

10782	12	12.50	1	1	1	1
10807	27	18.40	2	2	2	1
10586	66	23.80	3	3	3	2
10767	76	28.00	4	4	4	2
10898	54	30.00	5	5	5	3
10900	88	33.75	6	6	6	3
10883	48	36.00	7	7	7	4
11051	41	36.00	8	7	7	4
10815	71	40.00	9	9	8	5
10674	38	45.00	10	10	9	5
11057	53	45.00	11	10	9	6
10271	75	48.00	12	12	10	6

ROW_NUMBER: 排序，789
RANK： 当有重复值时，按最小值排 779
DENSE_RANK: 778

注意： ROW_NUMBER函数是在 DISTINCT子句之前处理的，所以不能排除重复的元素，
		可以先 GROUP BY 
eg:
	SELECT　val,ROW_NUMBER() OVER (ORDER BY val ) AS rownum
	FROM Sales.OrderValues
	GROUP BY val; 


7.1.2 偏移开窗函数

LAG:在当前行之前找 
LEAD:在之后找 

SELECT　custid ,orderid ,val,
	LAG(val,2,1) OVER (PARTITION BY custid
					ORDER BY orderdate ,orderid) AS prevval
FROM Sales.OrderValues;

FIRST_VALUE:
LAST_VALUE

SELECT custid,orderid,val,
	FIRST_VALUE(val) OVER (PARTITION BY custid
							ORDER BY orderdate,orderid
							ROWS BETWEEN UNBOUNDED PRECEDING
								AND CURRENT ROW)AS firstval,
	LAST_VALUE(val) OVER (PARTITION BY custid
							ORDER BY orderdate,orderid
							ROWS BETWEEN CURRENT ROW
								AND UNBOUNDED FOLLOWING)AS lastval
FROM Sales.OrderValues
ORDER BY custid,orderdate,orderid;

1	10643	814.50	814.50	933.50
1	10692	878.00	814.50	933.50
1	10702	330.00	814.50	933.50
1	10835	845.80	814.50	933.50
1	10952	471.20	814.50	933.50
1	11011	933.50	814.50	933.50
2	10308	88.80	88.80	514.40
2	10625	479.75	88.80	514.40
2	10759	320.00	88.80	514.40
2	10926	514.40	88.80	514.40
3	10365	403.20	403.20	660.00
3	10507	749.06	403.20	660.00



7.1.3 聚合开窗函数
SELECT orderid ,custid,val,
	100.*val/SUM(val) OVER() AS pctall,
	100.*val/SUM(val) OVER(PARTITION BY custid) AS pctcust
FROM Sales.OrderValues;

10643	1	814.50	0.0644609294708872005832	19.0615492628130119354083
10692	1	878.00	0.0694864285763523168963	20.5476246197051252047741
10702	1	330.00	0.0261167670047793446193	7.7229113035338169904048
10835	1	845.80	0.0669380652504314232698	19.7940556985724315469225
10952	1	471.20	0.0372915776140970520746	11.0273812309852562602387
11011	1	933.50	0.0738787939362470248550	21.8464778843903580622513
10926	2	514.40	0.0407104998401772571884	36.6655974910011048148544
10759	2	320.00	0.0253253498228163341763	22.8090808653195053280587
10625	2	479.75	0.0379682393046754260034	34.1958017035532271285505
10308	2	88.80	0.0070277845758315327339	6.3295199401261627285362


窗口范围： TODO 
ROWS BETWEEN 2 PRECEDING AND 1 FOLLOWING : 当前行的之前两行到后面一行之间的所有行

7.2 透视数据
将数据从行状态旋转到列状态

IF　OBJECT_ID('dbo.Orders','U') IS NOT NULL DROP TABLE dbo.Orders;

CREATE TABLE dbo.Orders
(
	orderid INT NOT NULL,
	orderdate DATE NOT NULL,
	empid INT NOT NULL,
	custid VARCHAR(5) NOT NULL,
	qty INT NOT NULL,
	CONSTRAINT PK_Orders PRIMARY KEY (orderid)
);

INSERT INTO dbo.Orders(orderid,orderdate,empid,custid,qty)
VALUES
	(30001,'20070802',3,'A',10),
	(10001,'20071224',2,'A',12),
	(10005,'20071224',1,'B',20),
	(40001,'20080109',2,'A',40),
	(10006,'20080118',1,'C',14),
	(20001,'20080112',2,'B',12),
	(40005,'20090212',3,'A',10),
	(20002,'20090216',1,'C',20),
	(30003,'20090418',2,'B',15),
	(30004,'20070418',3,'C',22),
	(30007,'20090907',3,'D',30)

SELECT * FROM　dbo.Orders;
10001	2007-12-24	2	A	12
10005	2007-12-24	1	B	20
10006	2008-01-18	1	C	14
20001	2008-01-12	2	B	12
20002	2009-02-16	1	C	20
30001	2007-08-02	3	A	10
30003	2009-04-18	2	B	15
30004	2007-04-18	3	C	22
30007	2009-09-07	3	D	30
40001	2008-01-09	2	A	40
40005	2009-02-12	3	A	10


SELECT empid,custid,SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY empid,custid;

2	A	52
3	A	20
1	B	20
2	B	27
1	C	34
3	C	22
3	D	30


使用标准SQL 透视
SELECT empid,
	SUM(CASE WHEN custid = 'A' THEN qty END ) AS A,
	SUM(CASE WHEN custid = 'B' THEN qty END ) AS B,
	SUM(CASE WHEN custid = 'C' THEN qty END ) AS C,
	SUM(CASE WHEN custid = 'D' THEN qty END ) AS D
FROM dbo.Orders
GROUP BY empid;

1	NULL	20	34	NULL
2	52	27	NULL	NULL
3	20	NULL	22	30

使用本地T-SQL PIVOT 运算符透视
SELECT　empid,A,B,C,D
FROM dbo.Orders
	PIVOT(SUM(qty)FOR custid IN (A,B,C,D)) AS P;

2	12	NULL	NULL	NULL
1	NULL	20	NULL	NULL
1	NULL	NULL	14	NULL
2	NULL	12	NULL	NULL
1	NULL	NULL	20	NULL
3	10	NULL	NULL	NULL
2	NULL	15	NULL	NULL
3	NULL	NULL	22	NULL
3	NULL	NULL	NULL	30
2	40	NULL	NULL	NULL
3	10	NULL	NULL	NULL

7.3 逆透视

标准SQL逆透视
SELECT * 
FROM (
		SELECT empid,custid,
		CASE custid 
			WHEN 'A' THEN A
			WHEN 'B' THEN B
			WHEN 'C' THEN C
			WHEN 'D' THEN D
		END AS qty
		FROM dbo.EmpCustOrders
			CROSS JOIN (VALUES ('A'),('B'),('C'),('D')) AS Custs(custid)) AS D
WHERE qty IS NOT NULL;



7.4 分组集
分组集就是用户据以分组的一个属性集。
SELECT empid ,custid,SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY empid,custid;
UNION ALL
SELECT empid,NULL,SUM(qty) AS sumqty
FROM dbo.empid
GROUP BY empid
UNION ALL
SELECT NULL,custid,SUM(qty) AS sumqty
FROM dbo.empid
GROUP BY custid
UNION ALL
SELECT NULL,NULL,SUM(qty) AS sumqty
FROM dbo.Orders;

2	A	52
3	A	20
1	B	20
2	B	27
1	C	34
3	C	22
3	D	30
1	NULL	54
2	NULL	79
3	NULL	72
NULL	A	72
NULL	B	47
NULL	C	56
NULL	D	30
NULL	NULL	205

7.4.1 GROUPING SETS 从属子句 可以在同一个查询中定义多个分组集
SELECT empid,custid,SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY 
	GROUPING SETS 
	(
		(empid,custid),
		(empid)
		(custid)
		()
	);

2	A	52
3	A	20
NULL	A	72
1	B	20
2	B	27
NULL	B	47
1	C	34
3	C	22
NULL	C	56
3	D	30
NULL	D	30
NULL	NULL	205
1	NULL	54
2	NULL	79
3	NULL	72

7.4.2 CUBE 从属子句
CUBE(empid,custid) = GROUPING SETS((empid,custid),(empid),(custid),())

7.4.3 ROLLUP 从属子句
ROLLUP(a,b,c) = GROUPING SETS((a,b,c),(a,b),(a),())
ROLLUP 假定输入成员之间是一个层次结构，

7.4.4 GROUPING 和 GROUPING_ID 函数
能够判断与分组集相关联的确定方式（即使分组列允许NULL标记）


练习：
7.6.1
SELECT custid,orderid,qty,
RANK() OVER(PARTITION BY custid ORDER BY qty) AS rnk,DENSE_RANK() OVER(PARTITION BY custid ORDER BY qty)AS drnk
FROM dbo.Orders;
A	30001	10	1	1
A	40005	10	1	1
A	10001	12	3	2
A	40001	40	4	3
B	20001	12	1	1
B	30003	15	2	2
B	10005	20	3	3
C	10006	14	1	1
C	20002	20	2	2
C	30004	22	3	3
D	30007	30	1	1


7.6.2
SELECT custid , orderid , qty ,
qty - LAG(qty) OVER (PARTITION BY custid ORDER BY orderdate,orderid) AS diffprev ,
qty - LEAD(qty) OVER (PARTITION BY custid ORDER BY orderdate,orderid) AS diffnext
FROM dbo.Orders

A	30001	10	NULL	-2
A	10001	12	2	-28
A	40001	40	28	30
A	40005	10	-30	NULL
B	10005	20	NULL	8
B	20001	12	-8	-3
B	30003	15	3	NULL
C	30004	22	NULL	8
C	10006	14	-8	-6
C	20002	20	6	NULL
D	30007	30	NULL	NULL


7.7.3 
SELECT empid,
	COUNT (CASE WHEN orderyear = 2007 THEN orderyear END ) AS cnt2007,
	COUNT (CASE WHEN orderyear = 2007 THEN orderyear END ) AS cnt2008,
	COUNT (CASE WHEN orderyear = 2009 THEN orderyear END ) AS cnt2009
FROM (SELECT empid,YEAR(orderdate) AS orderyear
		FROM dbo.Orders)AS D
GROUP BY empid;

1	1	1	1
2	1	1	1
3	2	2	2

SELECT empid,[2007] AS cnt2007,[2008]AS cnt2008,[2009]AS cnt2009
FROM (SELECT empid,YEAR(orderdate) AS orderyear
		FROM dbo.Orders) AS D
PIVOT(COUNT (orderyear)
	FOR orderyear IN ([2007],[2008],[2009]))AS P;
1	1	1	1
2	1	2	1
3	2	0	2


7.7.4 逆透视
SELECT *
FROM (SELECT empid,orderyear,
		CASE orderyear
		WHEN 2007 THEN cnt2007
		WHEN 2008 THEN cnt2008
		WHEN 2009 THEN cnt2009
	END AS numorders
	FROM dbo.EmpYearOrders
		CROSS JOIN(VALUES(2007),(2008),(2009))AS Years (orderyear)
	)AS D
WHERE numorders <> 0;


第八章 数据修改

8.1 插入数据
8.1.1 INSERT VALUES 语句
INSERT INTO dbo.Orders(orderid,orderdate,empid,custid,qty)
VALUES
	(30001,'20070802',3,'A',10),
	(10001,'20071224',2,'A',12)

8.1.2 INSERT SELECT 语句
INSERT INTO dbo.Orders(orderid,orderdate,empid,custid)
	SELECT orderid,orderdate,empid,custid
	FROM Sales.Orders
	WHERE shipcountry = 'UK';

8.1.3 INSERT EXEC 语句
可以将存储过程或动态SQL批处理返回的结果集插入到目标表中。
IF OBJECT_ID('Sales.usp_getorders','P')IS NULL
	DROP PROC Sales.usp_getorders;
GO 

CREATE PROC Sales.usp_getorders
	@country AS NVARCHAR(40)
AS

SELECT orderid,orderdate,empid,custid
FROM Sales.Orders
WHERE shipcountry = @country;
GO 

要测试此存储过程，可以为其指定输入国家"France" 来执行它
EXEC Sales.usp_getorders @country = 'France';



8.1.4 SELECT INTO 语句
IF OBJECT_ID('dbo.Orders','U') IS NOT NULL DROP TABLE dbo.Orders;

SELECT orderid,orderdate,empid,custid
INTO dbo.Orders
FROM Sales.Orders;

8.1.5 BULK INSERT语句
将来自文件的数据插入到一个现有的表中
BULK INSERT dbo.Orders FROM 'C:\temp\orders.txt'
	WITH(
		DATAFILETYPE = 'char',
		FILEDTERMINATOR = ',',
		ROWTERMINATOR = '\n'
		);

8.1.6 标识列属性和序列对象


8.2 删除数据

8.2.1 DELETE 语句 要进行筛选
DELETE FROM dbo.Orders
WHERE orderdate <'20070101';

8.2.2 TRUNCATE 语句
TRUNCATE TABLE dbo.T1;

TRUNCATE : 优势是最小日志记录方式，而 DELETE 是完全日志记录方式
所以 TRUNCATE 速度快

8.2.3 基于联接的DELETE　
DELETE FROM  Orders
FROM  dbo.Orders AS O
	JOIN dbo.Customers AS C 
		ON O.custid = C.custid
WHERE C.country = N'USA';



8.3 更新数据

8.3.1 update 语句
UPDATE dbo.OrderDetails
	SET discount = discount + 0.05
WHERE productid = 51;

8.3.2 基于联接的 update


8.4 合并数据
 MERGE

8.5 通过表表达式修改数据


8.6 使用TOP　和　OFFSET-FETCH 修改


8.7 OUTPUT子句

8.7.1 INSERT 与 OUTPUT























