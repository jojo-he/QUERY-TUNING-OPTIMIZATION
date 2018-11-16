T-SQL 性能调优秘籍


第一章 SQL 窗口函数

集合，排序，发布和偏移

集合：SUM COUNT MIN MAX 一个聚合函数的作用域是一个记录集，
排序： RANK DENSE_RANK ROW_NUMBER NTILE 
分布函数：PERCENT_RANK CUME_DIST PERCENTILE_CONT PERCENTILE_DISC
偏移函数：LAG LEAD FIRST_VALUE LAST_VALUE NTH_VALUE 

查询任务：
1 分页
2 去重(去除重复元素)
3 返回每组前n条记录
4 计算累积合计
5 对时间间隔进行操作
6 找出数据差距(gap) 和数据岛(island)
7 计算百分比
8 计算分布的模式
9 排序层次结构
10 数据透视
11 计算时效性(或计算近因)


SELECT orderid ,custid,val,
	CAST(100.* val / SUM(val) OVER (PARTITION BY custid) AS NUMERIC(5,2)) AS pctcust,
	val- AVG(val) OVER(PARTITION BY custid) AS diffcust
FROM Sales.OrderValues;

使用窗口函数


1.1.2 基于集合与迭代/游标的编程
SELECT orderid,orderdate,val,
       RANK () OVER(ORDER BY val DESC ) AS rnk
FROM Sales.OrderValues;

orderid	orderdate	val	rnk
10865	2015-02-02	16387.50	1
10981	2015-03-27	15810.00	2
11030	2015-04-17	12615.05	3
10889	2015-02-16	11380.00	4
10417	2014-01-16	11188.40	5
10817	2015-01-06	10952.85	6

排序的原理： 所有窗口都是由结果集中所有行组成，它们同时共存。对于每行，排名是这样计算的：数据集中所有特性val值大于
    当前值的记录数加1。
	
1.1.3 窗口函数替代方案的不足之处

窗口函数背后的理念是要定义一个函数的操作窗口或行集。

SELECT orderid,custid,val,
       CAST(100.*val / SUM(val) OVER(PARTITION BY custid) AS NUMERIC(5,2)) AS pctcust,
	   val - AVG(val) OVER(PARTITION BY custid) AS diffcust,
	   CAST(100.* val / SUM(val) OVER() AS NUMERIC(5,2)) AS pctall,
	   val - AVG(val) OVER() AS diffall
FROM Sales.OrderValues;

    SQL SERVER的优化器已为不同的窗口函数使用相同的窗口描述做了优化设定。如果发现不同的函数使用相同的窗口，SQL SERVER 对窗口
内的数据只访问一次（不管采用何种数据扫描方式）。例如，在扫描的前两个查询中，只对数据进行一次访问，同样，后两个函数（不
再分区的总合计和平均值），也只进行一次数据访问。
    窗口函数优于子查询的另一点是添加限制前的初始窗口时查询的结果集，
	例如：
	   SELECT orderid,custid,val,
              CAST(100.*val / SUM(val) OVER(PARTITION BY custid) AS NUMERIC(5,2)) AS pctcust,
	          val - AVG(val) OVER(PARTITION BY custid) AS diffcust,
	          CAST(100.* val / SUM(val) OVER() AS NUMERIC(5,2)) AS pctall,
	          val - AVG(val) OVER() AS diffall
       FROM Sales.OrderValues;
	   WHERE orderdate >= '20070101' AND orderdate < '20080101'
	   而子查询不得不在所有的子查询中重复添加筛选器，
	   
1.2 使用窗口函数的解决方案简介
    数据岛问题***

例子 ：
第一种方案
查看连续的数字的范围
SELECT *
FROM dbo.T1
2
3
7
8
9
11
15
16
17
28

SELECT col1,
	(SELECT MIN(B.col1)
		FROM dbo.T1 AS B
		WHERE B.col1 >=A.col1
		AND NOT EXISTS
			(SELECT *
				FROM dbo.T1 AS C
				WHERE C.col1 = B.col1 + 1))AS grp
FROM dbo.T1 AS A;

2	3
3	3
7	9
8	9
9	9
11	11
15	17
16	17
17	17
28	28


根据组标识符进行分组，返回每组的最大和最小的col值
SELECT MIN(col1) AS start_range,MAX(col1) AS end_range
FROM (SELECT col1,
		(SELECT MIN(B.col1)
		FROM dbo.T1 AS B
		WHERE B.col1 >= A.col1
		AND NOT EXISTS 
		(SELECT *
			FROM dbo.T1 AS C
			WHERE C.col1 = B.col1 +1))AS grp
		FROM dbo.T1 AS A) AS D
GROUP BY grp;

2	3
7	9
11	11
15	17
28	28

另一个方案
SELECT col1,ROW_NUMBER() OVER (ORDER BY col1 ) AS rownum
FROM dbo.T1;
2	1
3	2
7	3
8	4
9	5
11	6
15	7
16	8
17	9
28	10

SELECT col1,col1-ROW_NUMBER() OVER(ORDER BY col1) AS diff
FROM dbo.T1;

2	1
3	1
7	4
8	4
9	4
11	5
15	8
16	8
17	8
28	18

SELECT MIN(col1)AS start_range, MAX(col1) AS end_range
FROM (SELECT col1,
		--this difference is constant and unique per island
		col1 - ROW_NUMBER() OVER (ORDER BY col1) AS grp
		FROM dbo.T1) AS D
GROUP BY grp;

2	3
7	9
11	11
15	17
28	28


1.3 窗口函数中的元素
	3个核心元素是分区，排序和框架
1.3.1 分区
PARTITION BY 

SELECT custid,orderid,val,
	RANK () OVER(ORDER BY val DESC) AS rnk_all,
	RANK () OVER(PARTITION BY custid
				ORDER BY val DESC) AS rnk_cust
	FROM Sales.OrderValues;

1	11011	933.50	419	1
1	10692	878.00	440	2
1	10835	845.80	457	3
1	10643	814.50	469	4
1	10952	471.20	615	5
1	10702	330.00	686	6
2	10926	514.40	592	1
2	10625	479.75	608	2
2	10759	320.00	691	3
2	10308	88.80	797	4


1.3.2 排序

1.3.3 框架
框架是一个在分区内对行进行进一步限制的筛选器。
FIRST_VALUE,LAST_VALUE,NTH_VALUE 
ROWS 或 RANGE 
ROWS： 允许我们相对当前行的偏移行数来指定框架的起点和终点
RANGE: 可以以框架起终点的值与当前行的值的差异来定义偏移行数

SELECT empid,ordermonth,qty,
	SUM(qty) OVER (PARTITION BY empid
					ORDER BY ordermonth
					ROWS BETWEEN UNBOUND PRECEDING	
									AND CURRENT ROW ) AS runqty
FROM Sales.EmpOrders;

1	2006-07-01 00:00:00.000	121	121
1	2006-08-01 00:00:00.000	247	368
1	2006-09-01 00:00:00.000	255	623
1	2006-10-01 00:00:00.000	143	766
1	2006-11-01 00:00:00.000	318	1084
1	2006-12-01 00:00:00.000	536	1620

1.4 支持窗口函数的查询元素

1.4.1 查询逻辑处理

顺序：
1. FROM
2. WHERE
3. GROUP BY 
4. HAVING 
5. SELECT 
	5.1 Evalute Expressiopns(判断表达式) *
	5.2 删除重复数据
6. ORDER BY  *
7. OFFSET-FETCH/TOP 
* 表示允许窗口函数出现的阶段

1.4.2 支持窗口函数的子句

SELECT DISTINCT country, ROW_NUMBER() OVER (ORDER BY COUNTRY) AS rownum
FROM HR.Employees;
结果大出所料
UK	1
UK	2
UK	3
UK	4
USA	5
USA	6
USA	7
USA	8
USA	9

如果只想获得 UK USA  
UK	1
USA	2

WITH EmpCountries AS 
(
	SELECT DISTINCT country FROM HR.Employees
)
SELECT country,ROW_NUMBER() OVER(ORDER BY country) AS rownum
FROM EmpCountries;

UK	1
USA	2

SELECT O.empid,
	SUM(OD.qty) AS qty,
	RANK() OVER (ORDER BY SUM(OD.qty) DESC) AS rnk
FROM Sales.Orders AS O
	JOIN Sales.OrderDetails AS OD
		ON O.orderid = OD.orderid
WHERE O.orderid >= '20070101'
	AND O.orderdate <'20080101'
GROUP BY O.empid;

1.4.3 避开限制
如果根据窗口函数的计算结果进行筛选或分组该怎么办？
用 CTE 那样的表表达式或派生表
eg:
WITH C AS
(
	SELECT orderid,orderdate,val,
		RANK() OVER(ORDER BY val DESC) AS rnk
	FROM Sales.OrderValues
)
SELECT *
FROM C
WHERE rnk <=5;

10865	2008-02-02 00:00:00.000	16387.50	1
10981	2008-03-27 00:00:00.000	15810.00	2
11030	2008-04-17 00:00:00.000	12615.05	3
10889	2008-02-16 00:00:00.000	11380.00	4
10417	2007-01-16 00:00:00.000	11188.40	5

1.5 潜在的额外筛选器

1.6 窗口定义的重复使用  WINDOW 

SELECT empid,ordermonth,qty,
	SUM(qty) OVER W1 AS run_sum_qty,
	AVG(qty) OVER W1 AS run_avg_qty,
	MIN(qty) OVER W1 AS run_min_qty,
	MAX(qty) OVER W1 AS run_max_qty
	FROM Sales.EmpOrders
	WINDOW w1 AS (PARTITION BY empid
					ORDER BY ordermonth
					ROWS BETWEEN UNBOUND PRECEDING
					AND CURRENT ROW);

第二章 窗口函数详述
	
2.1 窗口聚合函数

2.1.2 支持的窗口元素
1.分区 
 分区元素使得我们将窗口限制为仅与当前行的分区特性有相同值的那些行。

2.排序与框架
	
	ROWS BETWEEN UNBOUNDED PRECEDING|
				<n> PRECEDING       |
				<n> FOLLOWING       |
				CURRENT ROW
			AND 
				UNBOUNDED FOLLOWING |
				<n> PRECEDING       |
				<n> FOLLOWING       |
				CURRENT ROW

UNBOUNDED FOLLOWING : 无下边界
<n> PRECEDING       : 当前行之前的行数
<n> FOLLOWING       : 当前行之后的行数
CURRENT ROW         : 起始行就是当前行


RANGE BETWEEN UNBOUNDED PRECEDING|
				<val> PRECEDING       |
				<val> FOLLOWING       |
				CURRENT ROW
			AND 
				UNBOUNDED FOLLOWING |
				<val> PRECEDING       |
				<val> FOLLOWING       |
				CURRENT ROW

SELECT empid,ordermonth,qty,
	(SELECT SUM(qty)
		FROM Sales.EmpOrders AS O2
		WHERE O2.empid = O1.empid
			AND O2.ordermonth BETWEEN DATEADD(month,-2,O1.ordermonth)
				AND O1.ordermonth
		)AS sum3month
FROM Sales.EmpPrders AS O1;


** ROWS 和 RANGE 的区别

对于使用RANGE的查询，上边界是CURRENT_ROW,默认包含与其相同值的行。


			窗口框架排除
*排除当前行
*排除组
*排除关联
*不予排除(默认项)
eg:
SELECT keycol,col1,
	COUNT(*) OVER (ORDER BY col1
					ROWS BETWEEN UNBOUNDED PRECEDING
							AND CURRENT ROW
					EXCLUDE CURRENT ROW) AS cnt
FROM dbo.T1;

EXCLUDE NO OTHERS 
EXCLUDE GROUP 
EXCLUDE TIES

2.1.3 对进一步筛选的一些想法  *不能运行的*
FILTER子句，用于筛选聚合谓词所作用行集的一种方法
<aggregate_function>(<input_expression>) FILTER(WHERE <search_condition>)

eg: 当前数量和从今天起前三个月的月平均数量（不是当前行的月份）
SELECT empid,ordermonth,qty,
	qty - AVG(qty)
			FILTER(WHERE ordermonth <= DATEADD(month,-3,CURRENT_TIMESTAMP))
			OVER(PARTITION BY empid) AS diff
FROM Sales.EmpOrders;
但是不支持FILTER ,可以在聚合函数的输入端使用CASE表达式
<aggregate_function>(<input_expression>) FILTER(WHERE <search_condition>)
<aggregate_function>(CASE WHEN <search_condition> THEN <input_expression> END )

SELECT empid,ordermonth,qty,
	qty - AVG(CASE WHEN ordermonth <= DATEADD(month,-3,CURRENT_TIMESTAMP) THEN qty END)
			OVER(PARTITION BY empid) AS diff
FROM Sales.EmpOrders;

2.1.4 DISTINCT 聚合 ****

返回到当前日期（含）为止，由当前销售人员处理的不同客户的订单数量	
SELECT empid,orderdate,orderid,val,
	COUNT(DISTINCT custid)OVER (PARTITION BY empid
								ORDER BY orderdate) AS numcusts
FROM Sales.OrderValues;

Use of DISTINCT is not allowed with the OVER clause.
OVER 子句中 不能用 DISTINCT ,所以使用一个变通的方法。
一种方法是借助 ROW_NUMBER函数，
SELECT empid,orderdate,orderid,custid,val,
	CASE 
		WHEN ROW_NUMBER() OVER(PARTITION BY empid,custid
									ORDER BY orderdate) = 1
			THEN custid
		END AS distinct_custid
	FROM Sales.OrderValues;

1	2015-01-15	10835	1	845.80	1
1	2015-03-16	10952	1	471.20	NULL
1	2014-09-22	10677	3	813.37	3
1	2014-02-21	10453	4	407.70	4
1	2014-06-04	10558	4	2089.90	NULL
1	2014-11-17	10743	4	319.20	NULL
1	2014-05-01	10524	5	3192.65	5
1	2014-08-11	10626	5	1503.60	NULL
1	2014-10-01	10689	5	472.50	NULL
1	2014-11-07	10733	5	1459.00	NULL

每一个客户的第一笔订单记录返回custid的值，随后发生的订单，其返回值为NULL.

对应的CTE
WITH C AS 
(
	SELECT empid,orderdate,orderid,custid,val,
	CASE 
		WHEN ROW_NUMBER() OVER (PARTITION BY empid, custid
									ORDER BY orderdate) =1
		THEN custid
	END AS distinct_custid
	FROM Sales.OrderValues
)

SELECT empid,orderdate,orderid,val,
	COUNT(distinct_custid) OVER(PARTITION BY empid
									ORDER BY orderdate) AS numcusts
FROM C;

1	2013-07-17	10258	1614.88	1
1	2013-08-01	10270	1376.00	2
1	2013-08-07	10275	291.84	3
1	2013-08-20	10285	1743.36	4
1	2013-08-28	10292	1296.00	5
1	2013-08-29	10293	848.70	6
1	2013-09-12	10304	954.40	6
1	2013-09-16	10306	498.50	7
1	2013-09-20	10311	268.80	8
1	2013-09-25	10314	2094.30	9
1	2013-09-27	10316	2835.00	9
1	2013-10-09	10325	1497.00	10


2.1.5 嵌套聚合 ***
分组聚合： GROUP BY 每组返回一个值
窗口聚合： 作用于记录窗口，返回基础查询中每一行对应的值。

以员工ID来分组计算某个值，同时又要算出所有员工的合计值
SELECT empid,
	SUM(val) AS emptotal,
	SUM(val) / SUM(SUM(val)) OVER() *100. AS pctcust
FROM Sales.OrderValues
GROUP BY empid;

拆分
1.
	SELECT empid,
		SUM(val) AS emptotal
	FROM Sales.OrderValues
	Group BY empid;

1	191437.20
2	166352.26
3	202459.37
4	232641.77
5	68621.64
6	73604.16
7	124333.98
8	126797.63
9	77308.08


2.
	SELECT empid,
	SUM(val) AS emptotal,
	SUM(val) / SUM(SUM(val)) OVER() *100. AS pctcust
FROM Sales.OrderValues
GROUP BY empid;

用CTE

WITH C AS 
(
	SELECT empid,
		SUM(val) AS emptotal
	FROM Sales.OrderValues
	GROUP BY empid
)

SELECT empid,emptotal,
	emptotal / SUM(emptotal) OVER() *100. AS pctcust
FROM C;

1	191437.20	15.150600
2	166352.26	13.165400
3	202459.37	16.022900
4	232641.77	18.411600
5	68621.64	5.430800
6	73604.16	5.825100
7	124333.98	9.840000
8	126797.63	10.034900
9	77308.08	6.118200

对 Sales.Order 表进行查询，返回每个员工相异的订单日期，及到当前日期（含）为止，当前员工处理的不同客户的数量，

WITH C AS 
(
	SELECT empid,orderdate,
	CASE 
		WHEN ROW_NUMBER() OVER(PARTITION BY empid,custid
								ORDER BY orderdate) =1
		THEN custid
	END AS distinct_custid
	FROM Sales.Orders
)
SELECT empid,orderdate,
	SUM(COUNT(distinct_custid)) OVER(PARTITION BY empid
										ORDER BY orderdate)AS numcusts
	FORM C 
	GROUP BY empid,orderdate;

1	2013-07-17	1
1	2013-08-01	2
1	2013-08-07	3
1	2013-08-20	4
1	2013-08-28	5
1	2013-08-29	6
1	2013-09-12	6
1	2013-09-16	7
1	2013-09-20	8
1	2013-09-25	9
1	2013-09-27	9
1	2013-10-09	10

如果用这个，会报错
SELECT empid,orderdate,
	COUNT(distinct_custid) OVER(PARTITION BY empid
										ORDER BY orderdate)AS numcusts
	FROM C 
	GROUP BY empid,orderdate;

Column 'C.distinct_custid' is invalid in the select list because it is not contained in either an aggregate function or the GROUP BY clause.


2.2 排名开窗函数
2.2.1 

2.2.2 ROW_NUMBER

eg:
SELECT orderid,val,
	ROW_NUMBER() OVER (ORDER BY orderid) AS rownum
	FROM Sales.OrderValues
	ORDER BY rownum;

可以使用COUNT窗口聚合来产生从逻辑上与ROW_NUMBER函数相同的行号
SELECT orderid,val,
	COUNT(*) OVER(ORDER BY orderid
					ROWS UNBOUND PRECEDING) AS rownum
FROM Sales.OrderValues;

SELECT orderid,val,
	(SELECT COUNT(*)
		FROM Sales.OrderValues AS O2
		WHERE O2.orderid <= O1.orderid)AS rownum
FROM Sales.OrderValues AS O1;
该例子是，计算有多少行的排序特性（orderid）小于或等于当前行的排序特性
相当于
SELECT orderid,val,
	ROW_NUMBER() OVER (ORDER BY orderid) AS rownum
	FROM Sales.OrderValues
	ORDER BY rownum;
10248	440.00	1
10249	1778.60	2
10250	1478.40	3
10251	654.06	4
10252	3597.90	5
10253	1444.80	6
10254	556.62	7
10255	2490.50	8
10256	517.80	9
10257	1119.90	10

确定性：
SELECT orderid,orderdate,val,
	ROW_NUMBER() OVER(ORDER BY orderdate DESC) AS rownum
FROM Sales.OrderValues;
从技术层面，如果有相同的orderdate，对应的部分每次运行，可能不完全相同，这就不确定了(实际上SQL在物理实现方面的设计(优化)所导致)
所以，如果希望得到唯一确定的顺序，可以通过在窗口排序中添加一个决定性属性。
eg:
SELECT orderid,orderdate,val,
	ROW_NUMBER() OVER (ORDER BY orderdate DESC,orderid DESC) AS rownum
FROM Sales.OrderValues;

2.2.3 NTILE 
NTILE函数把窗口分区里的数据行分成数量大致相同的块
SELECT orderid ,val,
	ROW_NUMBER() OVER (ORDER BY val) AS rownum,
	NTILE(10) OVER(ORDER BY val) AS title
FROM Sales.OrderValues;

分页与分块的区别***
在分页中，页的大小是常量，并且页码是动态的——查询结果集除以页面大小后得到的数值。
而分块中，块的数量是常量，块的大小是动态的——行的数量除以设定的块的数值后得到的值。

块的确定性*
SELECT orderid,val,
	ROW_NUMBER() OVER(ORDER BY val,orderid)AS rownum,
	NTILE(10) OVER(ORDER BY val,orderid) AS title
FROM Sales.OrderValues;

2.2.4 RANK 和 DENSE_RANK 
	
2.3 分布函数 为静态统计服务提供数据的分布情况
1. 排名分布函数 PERCENT_RANK(百分位排名)和CUME_DIST(累积分布)
2. 逆分布函数 PERCENT_CONT 和 PERCENTILE_DISC

2.3.1 支持的窗口元素
	WITHIN GROUP 
2.3.2 排名分布函数 *****
假设rk为数据行的RANK 值，RANK行数的窗口描述与分布式函数的窗口描述
假设nr为窗口分区内数据行的行数。
假设np为领先或与当前行的排序值相同的行数目(为比当前rk减1大的最小rk值,如果)

SELECT testid,studentid,score,
	PERCENT_RANK() OVER (PARTITION BY testid ORDER BY score) AS percentrank,
	CUME_DIST() OVER(PARTITION BY testid ORDER BY score) AS CUME_DIST
FROM Stats.Scores;

10782	12.50	1	1
10807	18.40	2	1
10586	23.80	3	1
10767	28.00	4	1
10898	30.00	5	1
10900	33.75	6	1
10883	36.00	7	1
11051	36.00	8	1
10815	40.00	9	1
10674	45.00	10	1
11057	45.00	11	1
10271	48.00	12	2

testid	studentid	score	percentrank	CUME_DIST
Test ABC	Student E	50	0	0.111111111111111
Test ABC	Student C	55	0.125	0.333333333333333
Test ABC	Student D	55	0.125	0.333333333333333
Test ABC	Student H	65	0.375	0.444444444444444
Test ABC	Student I	75	0.5	0.555555555555556
Test ABC	Student B	80	0.625	0.777777777777778
Test ABC	Student F	80	0.625	0.777777777777778
Test ABC	Student A	95	0.875	1
Test ABC	Student G	95	0.875	1

计算百分位排名和累计分布
WITH C AS 
(
	SELECT testid,studentid,score,
		RANK() OVER(PARTITION BY testid ORDER BY score) AS rk,
		COUNT (*) OVER(PARTITION BY testid) AS numorders
	FROM States.Scores
)

SELECT testid,studentd,score,
	1.0 * (rk -1) /(nr -1) AS percentrank,
	1.0 * (SELECT COLAESCE (MIN(C2.rk) -1,C1.nr)
			FROM C AS C2
			WHERE C2.rk > C1.rk) / nr AS CUME_DIST
FROM C AS C1;

2.3.3 逆分布排序
 逆分布函数，通常叫做百分位，可以当做排名分布函数的倒数。
 接受一个百分比作为输入，返回其在组中所对应的值


 2.4 偏移函数：LAG
 	2.4.1 支持的窗口元素
 	第一类： 偏移量是相对于当前行 LAG LEAD
 	第二类： 相对于窗口框架的开端和末尾的 FIRST_VALUE LAST_VALUE NTH_VALUE(不支持)



第三章 排序集合函数

3.1 假设集合函数
排名集合函数：RANK 和 DENSE_RANK 
排名分布集合函数：PERCENT_RANK 和 CUME_DIST
窗口函数和排序函数对于排序是有区别的:前者是在窗口内进行排序，后者是在分组内进行排序

3.1.1 RANK 

标准的RANK排名集合函数的语法（SQL不支持这个语法）
DECLARE @val AS NUMERIC(12,2) = 1000.00;

SELECT custid,
	COUNT(CASE WHEN val < @val THEN 1 END ) + 1 AS rnk
FROM Sales.OrderValues
GROUP BY custid; 
1	7
2	5
3	6
4	10
5	7
6	8
7	6
8	3
9	9
10	7

3.1.2 DENSE_RANK
作为窗口函数：对分区内所有行根据行的排序值(不是行数) 进行相异排序，结果返回行的排名是小于该行的排序值的行数加1.
作为排序集合函数：对于输入值@val，DENSE_RANK返回的排名是组内相异排序值小于@val的行数加1.

SQL SERVER 不支持这个语法
DECLARE @val AS NUMERIC(12,2)=1000.00;

SELECT custid,
	DENSE_RANK(@val) WITH GROUP(ORDER BY val) AS densernk
FROM Sales.OrderValues
GROUP BY custid;

替代方法：当排序值小于@val时，DENSE_RANK返回的不是一个常数，而是返回val，并在表达式中使用DISTINCT子句
DECLARE @val AS NUMERIC(12,2)=1000.00;

SELECT custid,
	COUNT(DISTINCT CASE WHEN val < @val THEN val END) +1 AS densernk
FROM Sales.OrderValues
GROUP BY custid;

3.1.3 PERCENT_RANK 
eg: 有一个Scores表以及一个给定的测试分数@score,把这个分数加入到所有的测试中，得到每个测试中这个分数的百分比排名
DECLARE @score AS TINYINT = 80;

SELECT testid,
	PERCENT_RANK(@score) WITHIN GROUP(ORDER BY score) AS percentrank
FROM States.Scores
GROUP BY testid;

别的方法
DECLARE @score AS TINYINT= 80;

WITH C AS 
(
	SELECT testid,
		COUNT(CASE WHEN score < @ score THEN 1 END) +1 AS rk,
		COUNT(*)+1 AS nr
	FROM States.Scores
	GROUP BY testid
)

SELECT testid,1.0*(rk-1)/(nr-1) AS percentrank
FROM C;

3.1.4 CUME_DIST
一个值加入到所在组中时，这个输入值的累积分布是什么。
DECLARE @score AS TINYINT = 80;

SELECT testid,
	CUME_DIST(@SCORE) WITH GROUP(ORDER BY score) AS CUME_DIST
FROM States.Scores
GROUP BY testid;

另一种方法
DECLARE @score AS TINYINT = 80;

WITH C AS
(
	SELECT testid,
		COUNT(CASE WHEN score <= @score THEN 1 END) + 1 AS np,
		COUNT(*) + 1 AS nr
	FROM States.Scores
	GROUP BY testid 
)
SELECT testid,1.0*np/nr AS CUME_DIST
FROM C;

3.1.5 通用的解决方法 ***
通用解决方法：
	1.把输入值与现有的组成员整合在一起
	2.调用窗口函数
	3.筛选出输入值的结果

通用形式 (略)
***
通用形式的具体例子
DECLARE @val AS NUMERIC(12,2) = 1000.00;

SELECT custid, rnk ,densernk
FROM Sales.Customers AS P
	CROSS APPLY(SELECT 
					RANK() OVER(ORDER BY val) AS rnk,
					DENSE_RANK() OVER (ORDER BY val) AS densernk,
					return_flag
				FROM (SELECT val,O AS return_flag
						FROM Sales.OrderValues AS DECLARE
						WHERE D.custid = P.custid
						
						UNION ALL 

						SELECT @val,l) AS U) AS A
WHERE return_flag = 1;

3.2 逆分布函数

3.3 偏移函数
例子：
返回每个客户的第一个，最后一个和第三个订单金额
WITH OrdersRN AS 
(
	SELECT custid,val,
	ROW_NUMBER() OVER(PARTITION BY custid
						ORDER BY orderdate,orderid)AS rna,
	ROW_NUMBER() OVER(PARTITION BY custid
						ORDER BY orderdate DESC, orderid DESC)AS rnk,DENSE_RANK
	FROM Sales.OrderValues
)

SELECT custid,
	MAX(CASE WHEN rna = 1 THEN val END) AS firstorderval,
	MAX(CASE WHEN rnd = 1 THEN val END) AS lastorderval,
	MAX(CASE WHEN rna = 3 THEN val END) AS thirdorderval
FROM OrdersRN
GROUP BY custid;

例子：排序技术来取得第一个和最后一个

第一步，生成连接字符串：
SELECT custid,
	CONVERT(CHAR(8),orderdate,112)
		+ STR(orderid ,10)
		+ STR(val,14,2)
		COLLATE Latin_GENERAL_BIN2 AS score
FROM Sales.OrderValues;

WITH C AS 
(
	SELECT custid,
	CONVERT(CHAR(8),orderdate,112)
		+ STR(orderid,10)
		+ STR(val,14,2)
		COLLATE Latin1_General_BIN2 AS score
	FROM Sales.OrderValues
)
SELECT custid,
	CAST(SUBSTRING(MIN(s),19,14) AS NUMERIC(12,2)) AS firstorderval,
	CAST(SUBSTRING(MAX(s),19,14) AS NUMERIC(12,2)) AS lastorderval
FROM C
GROUP BY custid;

3.4 字符串连接***


第四章 窗口函数的优化
CREATE TABLE dbo.Accounts
(
	actid INT NOT NULL,
	actname VARCHAR(50) NOT NULL,
	CONSTRAINT PK_Accounts PRIMARY KEY(actid)
);

CREATE TABLE dbo.Transactions
(
	actid INT NOT NULL,
	tranid INT NOT NULL,
	val MONEY NOT NULL,
	CONSTRAINT PK_Transactions PRIMARY KEY (actid,tranid),
	CONSTRAINT FK_Transactions_Accounts
		FOREIGN KEY(actid)
		REFERENCES dbo.Accounts(actid)
);

INSERT INTO dbo.Accounts(actid,actname) VALUES
	(1,'account 1'),
	(2,'account 2'),
	(3,'account 3');

INSERT INTO dbo.Transactions(actid,tranid,val) VALUES
	(1,1,4.00),
	(1,2,-200),
	(1,3,5.00),
	(1,4,2.00),
	(1,5,1.00),
	(1,6,3.00),
	(1,7,-4.00),
	(1,8,-1.00),
	(1,9,-2.00),
	(1,10,-3.00),
	(2,1,2.00),
	(2,2,1.00),
	(2,3,5.00),
	(2,4,1.00),
	(2,5,-5.00),
	(2,6,4.00),
	(2,7,2.00),
	(2,8,-4.00),
	(2,9,-5.00),
	(2,10,4.00),(3,1,-3.00),
	(3,2,3.00),
	(3,3,-2.00),
	(3,4,1.00),
	(3,5,4.00),
	(3,6,-1.00),
	(3,7,5.00),
	(3,8,3.00),
	(3,9,5.00),
	(3,10,-3.00)


4.2 索引指南
4.2.1 POC索引
POC(Partitioning 分区,Ordering 排序，Covering 覆盖)

当缺少POC索引，执行计划会引入一个排序迭代器，这会导致处理大型输入集时，需要相当大的开销。

CREATE INDEX idx_actid_val_i_traind
	ON dbo.Transactions(actid /* P */,val /* P */)
	INCLUDE(tranid /* C */);

4.2.2 反向扫描
索引每个级别中的页都通过一个双向链表链接；可以双向扫描，所以要考虑它的选择情况

* 第一个特别的地方是排序的正向扫描可以受益于 并行处理


eg:
SELECT actid,tranid,val,
	ROW_NUMBER() OVER(PARTITION BY actid ORDER BY val)AS rownum
FROM dbo.Transactions;

SELECT actid,tranid,val,
	ROW_NUMBER() OVER(PARTITION BY actid ORDER BY val DESC) AS rownum
FROM dbo.Transactions;

优化器有缺点。值的顺序对于要被扫描的不同分区列值是不重要的。
重要的是，需要完全按照窗口排序子句定义的顺序来扫描每个分区的值。
所以反向扫描索引可以为窗口函数提供正确排序的值。

有两种索引可以防止排序产生：一种索引带有键列表(actid,val DESC),另一种索引恰好为降序(actid DESC,val)
在前一种情况下，使用正向排序扫描；在后一种情况下,使用反向排序扫描。

有趣的是： 在最后一个查询中加一个 ORDER BY 可以减少一个排序迭代器
SELECT actid,tranid,val,
	ROW_NUMBER() OVER(PARTITION BY actid ORDER BY val DESC) AS rownum
FROM dbo.Transactions
ORDER BY actid DESC;
注意：反向扫描不能像正向扫描一样并行化，但是可以通过增加 ORDER BY 子句来提高查询性能。***

4.2.3 列存储索引

采用压缩（减少I/O）以及新的批处理模式来处理数据而提高了性能。

注意：处理窗口函数的迭代器通常仍会以行模式来运行。如果想要提高窗口函数的性能，通常需要专注于传统的方式，如POC索引，它会避免对数据进行排序。

4.3 排名函数

两个帮助处理排名函数的关键迭代器是Segment和Sequence Project.
Segment 用来同时发送一段行给下一个迭代器，可以用它的 GROUP BY 属性定义分段表达式列表。
Segment 迭代器为每一行产生有个标记，称为SegmenN(N为一些数字，eg:Segment1004),表明该行是否是该段的第一行

Sequence Project 迭代器负责排序函数的实际运算。它对前面的Segment 迭代器产生的标志进行评估，对前一行的
排名值进行复位、保持或增加。Sequence Project 迭代器产生包含为ExpressionN的排名值（eg:Expr1003）

eg:
SELECT actid,tranid,val,
	ROW_NUMBER() OVER(PARTITION BY actid ORDER BY val) AS rownum
FROM dbo.Transactions;
分析：
因为已存在一个POC索引，所以按排序方式扫描它，如果没有这样的一个索引，将会增加一个昂贵的排序迭代器。
其次，Segment迭代器根据分区列actid创建分组，产生一个标志(SegmentN)来指示新分区的开始。每当SegmentN表明要开始
一个新的分区时，Sequence Project迭代器就生成行值1(命名为ExpcN);否则，它将前面的行值加1.（什么意思？？***）


一个有趣的点***
ORDER BY (SELECT NULL),SQL SERVER 可以接受它,优化器展开或扩展表达式，并认为所有行的排序时相同的，
因此，它从输入数据中清除了排序要求。
SELECT actid,tranid,val,
	ROW_NUMBER() OVER(PARTITION BY actid ORDER BY val) AS rownum
FROM dbo.Transactions;
Ordered: TRUE

SELECT actid,tranid,val,
	ROW_NUMBER() OVER(ORDER BY (SELECT NULL) ) AS rownum
FROM dbo.Transactions;
Ordered: False

观察Index Scan 迭代器的属性，Ordered属性为False,这意味着不需要迭代器按索引顺序返回数据。

4.3.2 NTILE
NTILE的实现（棘手的部分时如何计算各分区中的行数，因为只遍历一遍数据不够充分。这是由于需要为每个单独的行
统计分区的行数，只有在扫描完所有的分区的行后才能知道这个结果。优化器如何实现的呢？***）

SELECT actid,trainid,val,
	NTILE(100) OVER(PARTITION BY actid ORDER BY val)

优化器对这个查询执行了以下步骤： 截图：NTILE 20181011
*如果存在POC索引，则从POC索引
*根据分区元素（这里是actid）对行分段
*同时把一个分区的行存储到一个工作表中(这个步骤是计划中上面的Table Spool迭代器)
*读取假脱机(spool)两次（详见图片下面的两个Table Spool 迭代器）—— 一个是通过Stream Aggregate 迭代器进行统计行数
而另一个获得详细的行信息。
*联接聚合和详细的行信息得到同一行的行数与具体信息。
*再次根据分区元素(这里是actid) 对数据分段。
*使用Sequence Project 迭代器计算组号。

注意：Table Spool迭代器使用的工作表保存在tempdb中。即使计划中它的百分比似乎很低，实际上它的开销也是相当高的

4.3.3 RANK 和 DENSE_RANK

回想一下，前面显示的ROW_NUMBER函数的执行计划有一个Segment迭代器，按照分区元素分组。RANK和DENSE_RANK
的执行计划是相似的，但它们需要两个Segment迭代器，按照分区和排序两个元素分组。

SELECT actid,tranid,val,
	RANK() OVER(PARTITION BY actid ORDER BY val) AS rownum
FROM dbo.Transactions;
图：RANK执行计划
第一个Segment迭代器按actid分组，返回标志Segment1004,第二个是按actid、val分组，返回标志Segment1005。
当Segment1004表明这是分区中第一行时，Sequence Project 返回1；否则，当Segment1005表明排序值已更改时，
Sequence Project 返回各自的行数。如果排序值没有改变，Sequence Project 返回与原来排名相同的值。

4.4 利用APPLY提高并行度
	可以优化窗口函数查询的并行
	应用场景:当涉及窗口分区子句并且内置的并行度不产生最佳的结果，或只是没有被使用时，这种情况就有用。
eg:
SELECT actid,tranid,val,
	ROW_NUMBER() OVER(PARTITION BY actid ORDER BY val)AS rownumasc,
	ROW_NUMBER() OVER(PARTITION BY actid ORDER BY val DESC) AS rownumdesc
FROM dbo.Transactions;
没有APPLY的执行计划
因为调用两个ROW_NUMBER函数，并且窗口的定义各不相同，即使索引都存在，也不能都依靠POC索引。只有一个
函数可以得益于POC索引；其他函数需要一个排序迭代器来进行所需的数据排序。

使用并行APPLY技术
SELECT C.actid,A.*
FROM dbo.Accounts AS C 
	CROSS APPLY (SELECT tranid,val,ROW_NUMBER() OVER(ORDER BY val) AS rownumasc,
					ROW_NUMBER() OVER(ORDER BY val DESC)AS rownumdesc
					FROM dbo.Transactions AS T
					WHERE T.actid = C.actid)AS A;
*** TODO

4.5 聚合和偏移函数
	聚合和偏移函数有没有带排序与框架会极大的影响性能。因此，分两种情况
4.5.1 没有排序和框架
	
SELECT actid,tranid,val,
	MAX(val) OVER(PARTITION BY actid) AS maxorderdate
FROM dbo.Transactions;
图：没有排序的执行计划1

该计划将执行下列步骤：
*从POC索引读取行
*根据分区元素（这里是actid）对行分段
*一次把一个分区的行保存到一个工作表中(这一步骤由计划中上层的Table Spool迭代器完成)
*读取假脱机两次(执行计划中底部的两个Table Spool迭代器)—— 一次是联合 一个是Stream Aggregate迭代器来
计算MAX聚合，另一次获得具体数据行信息。
*为同一个目标行同时返回聚合和具体的元素

注意：假脱机部分不使用内存中的优化的工作表，而是使用磁盘上的tempdb中的表。

TODO *** 
不理解，先填坑
1.
	WITH C AS 
	(
		SELECT actid,tranid,val,
			MAX(val) OVER(PARTITION BY actid) AS mx
		FROM dbo.Transactions
	)
	SELECT actid,tranid,val
	FROM C
	WHERE val = mx;

2.
	WITH Aggs AS 
	(
		SELECT actid,MAX(val) AS mx
		FROM dbo.Transactions
		GROUP BY actid
	)
	SELECT T.actid,T.tranid,T.val,A.mx
	FROM dbo.Transactions AS T
		JOIN Aggs AS A
			ON T.actid = A.actid;
3.
	WITH Aggs AS 
	(
		SELECT actid,MAX(val) AS mx
		FROM dbo.Transactions
		GROUP BY actid
	)
	SELECT T.actid,T.traind,T.val
	FROM dbo.Transactions AS T
		JOIN Aggs AS Aggs
			ON  T.actid = A.actid
			AND T.val = A.mx;


4.5.2 有排序和框架

	讨论3个利用和框架优化的示例

1. UNBOUNDED PRECEDING：快速通道示例

题外话(先描述Window Spool 和 Stream Aggregate迭代器的作用，两个迭代器在内部作为一个迭代器来实现，
		但在执行计划中体现为两个)
WINDOW Spool迭代器的用途是扩展每个源行至其适用的框架行。（最坏的情况下可能发生）迭代器产生一个特性来标识窗口
框架，名字为WindowCountN.
Stream Aggregate迭代器根据WindowCountN对分组并计算聚合。

有个问题，一旦数据被分组，在哪里得到行的详细元素？为此，总是把当前行添加到Window Spool中，Stream Aggregate迭代器
返回行的具体元素。***


第五章： 利用窗口函数的T-SQL 解决方法


5.1 数字虚拟表
	主要作用：生成日期和时间值序列，及分裂值列表。

SELECT c FROM (VALUES(1),(1)) AS D(c)

WITH 
	LO AS (SELECT c FROM (VALUES(1),(1)) AS D(c)),
	L1 AS (SELECT 1 AS c FROM LO AS A CROSS JOIN LO AS B),
	L2 AS (SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
	L3
	L4
	L5
	Nums AS (SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL) ) AS rownum
				FROM L5)
	SELECT @low + rownum -1 AS n
	FROM Nums
	ORDER BY rownum
	OFFSET O ROWS FETCH FIRST @high - @low +1 ROWS ONLY;

IF OBJECT_ID('dbo.GetNums','IF') IS NOT NULL DROP FUNCTION dbo.GetNums;
GO 
CREATE FUNCTION dbo.GetNums(@low AS BINGINT,@high AS BIGINT) RETURNS TABLE
AS 
RETURNS
	WITH
		LO AS (SELECT c FROM (VALUES(1),(1)) AS D(c)),
		L1 AS (SELECT 1 AS c FROM LO AS A CROSS JOIN LO AS B),
		L2 AS (SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
		L3
		L4
		L5
	Nums AS (SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL) ) AS rownum
				FROM L5)
	SELECT @low + rownum -1 AS n
	FROM Nums
	ORDER BY rownum
	OFFSET O ROWS FETCH FIRST @high - @low +1 ROWS ONLY;
	GO

eg: SELECT n FROM dbo.GetNums(11,20);


5.2 日期和时间值序列
	生成一个日期和时间序列，序列的范围是输入值@start 到@end,且有一定的时间间隔(如一天，12小时)
	使用场景为：数据仓库中的时间维度，应用程序的运行时间安排以及其他。

	调用GetNums函数
	eg: 生成2012年12月1日到2012年2月12日的日期序列
	DECLARE 
	@start AS DATE = '20120201',
	@end AS DATE = '20120112';

SELECT DATEADD(day,n,@start) AS dt
FROM dbo.GetNums(0,DATEDIFF(day,@start,@end)) AS Nums;

eg: 12小时 
DECLARE
	@start AS DATETIME2 = '2012-02-12 00:00:00:0000000',
	@end   AS DATETIME2 = '2012-02-18 12:00:00:0000000';

SELECT DATEADD(hour,n*12,@start) AS dt
FROM dbo.GetNums(0,DATEDIFF(hour,@start,@end)/12) AS Nums;


5.3 序列值
	整数序列键

5.3.1 更新列的值唯一值

SELECT 0 AS orderid,custid,empid,orderdate
	INTO Sales.MyOrders
	FROM Sales.Orders;

SELECT * FROM Sales.MyOrders;

orderid	custid	empid	orderdate
0	85	5	2006-07-04 00:00:00.000
0	79	6	2006-07-05 00:00:00.000
0	34	4	2006-07-08 00:00:00.000
0	84	3	2006-07-08 00:00:00.000
0	76	4	2006-07-09 00:00:00.000
0	34	3	2006-07-10 00:00:00.000

orderid     custid      empid       orderdate
----------- ----------- ----------- -----------------------
1           85          5           2006-07-04 00:00:00.000
2           79          6           2006-07-05 00:00:00.000
3           34          4           2006-07-08 00:00:00.000
4           84          3           2006-07-08 00:00:00.000
5           76          4           2006-07-09 00:00:00.000
6           34          3           2006-07-10 00:00:00.000
7           14          5           2006-07-11 00:00:00.000
8           68          9           2006-07-12 00:00:00.000
9           88          3           2006-07-15 00:00:00.000
10          35          4           2006-07-16 00:00:00.000

5.3.2 数字序列的应用

保证完整序列值的常用方法：在一个表中存储最后一个值，每当需要一个新的值时，对存储的值加一，然后使用这个新值

IF OBJECT_ID('dbo.mysequence','U') IS NOT NULL DROP TABLE dbo.Mysequence;
CREATE PROC dbo.GetSequence
	@val AS INT OUTPUT
AS 
UPDATE dbo.mysequence
	SET @val = val +1;
GO

应用场景：获得整个范围的序列值
eg:
用于对一些表进行多行插入，首先更改存储过程以接受输入参数(@n),这个参数表示范围的大小。然后存储
过程对MySequence 表的val列递增@n,并返回新范围内的第一个值作为输出参数。
ALTER PROC dbo.GetSequence
	@val AS INT OUTPUT,
	@n AS INT =1
AS 
UPDATE dbo.Mysequence
	SET @val = val + 1,
		val += @n;
GO


DECLARE @firstkey AS INT , @rc AS INT;

DECLARE @CustssStage AS TABLE
(
	custid INT,
	rownum INT
);

INSERT INTO @CustsStage(custid,rownum)
	SELECT custid,ROW_NUMBER() OVER(ORDER BY (SELECT NULL))
	FROM Sales.Customers
	WHERE country = N'UK';

SET @rc = @@rowcount;

EXEC dbo.GetSequence @val = @firstkey OUTPUT,@n = @rc;

SELECT custid,@firstkey + rownum -1 AS keycol,col1
FROM @CustsStage;
上述目的：产生这些Customers的代理键，并最终将这些值插入数据仓库的Customer维度中。
可以先将以上查询的结果集，随同由ROW_NUMBER函数生成的从1开始的唯一整数(rownum),一起填充到一个表变量中。
然后从@@rowcount函数收集受影响的行数，并存储到一个局部变量(@rc)中。接着就可以调用前面创建的存储过程
GetSequence,传递@rc 作为要分配的范围的大小，把范围中的第一个键存储到一个局部变量中(@firstkey)。
最后，查询表变量，并通过表表达式@firstkey+rownum-1来计算单独的序列值。

5.4 分页
	ROW_NUMBER函数可用于分页
	为了获得最佳性能，要定义窗口排序元素为索引键的索引，索引还包括出现在查询中其于列
	第一步。定义索引
	CREATE UNIQE INDEX idx_od_oid_i_cid_eid
		on Sales.Orders(orderdate,orderid)
		INCLUDE(custid,empid);
	然后输入一个页码和页面大小，例：返回第3页的内容，页面大小为25行，即行数为51——75行：
	DECLARE 
		@pagenum AS INT =3,
		@pagesize AS INT = 25;

	WITH C AS 
	(
		SELECT ROW_NUMBER() OVER (ORDER BY orderdate,orderid) AS rownum,
			orderid,orderdate,custid,empid
		FROM Sales.Orders
	)
	SELECT orderid,orderdate,custid,empid
	FROM C
	WHERE rownum BETWEEN (@pagenum -1) * @pagesize +1
		AND @pagenum * @pagesize
	ORDER BY rownum;

orderid     orderdate               custid      empid
----------- ----------------------- ----------- -----------
10298       2006-09-05 00:00:00.000 37          6
10299       2006-09-06 00:00:00.000 67          4
10300       2006-09-09 00:00:00.000 49          2
10301       2006-09-09 00:00:00.000 86          8
10302       2006-09-10 00:00:00.000 76          4
10303       2006-09-11 00:00:00.000 30          7
10304       2006-09-12 00:00:00.000 80          1
10305       2006-09-13 00:00:00.000 55          8
10306       2006-09-16 00:00:00.000 69          1
10307       2006-09-17 00:00:00.000 48          2
10308       2006-09-18 00:00:00.000 2           7
10309       2006-09-19 00:00:00.000 37          3
10310       2006-09-20 00:00:00.000 77          8
10311       2006-09-20 00:00:00.000 18          1
10312       2006-09-23 00:00:00.000 86          2
10313       2006-09-24 00:00:00.000 63          2
10314       2006-09-25 00:00:00.000 65          1
10315       2006-09-26 00:00:00.000 38          4
10316       2006-09-27 00:00:00.000 65          1
10317       2006-09-30 00:00:00.000 48          6
10318       2006-10-01 00:00:00.000 38          8
10319       2006-10-02 00:00:00.000 80          7
10320       2006-10-03 00:00:00.000 87          5
10321       2006-10-03 00:00:00.000 38          3
10322       2006-10-04 00:00:00.000 58          7

替代的方法：使用OFFSET/FETCH筛选出正确的页面行
DECLARE
		@pagenum AS INT =3,
		@pagesize AS INT = 25;

SELECT orderid,orderdate,custid,empid
	FROM Sales.Orders
	ORDER BY orderdate,orderid
	OFFSET (@pagenum -1 ) * @pagesize ROWS FETCH NEXT @pagesize ROWS ONLY;

5.5 删除重复

方法一
WITH C AS 
(
	SELECT orderid,
		ROW_NUMBER() OVER(PARTITION BY orderid
						ORDER BY (SELECT NULL)) AS n
	FROM Sales.Myorders
)
DELETE FROM C
WHERE n >1;

方法二： 当要删除大量行时，方法一会很慢，所以考虑使用最小日志记录操作，如SELECT INTO,把非重复行
复制到另一个表中；删除原始表；重命名新表为原始表；然后重新创建目标表上的约束、索引和触发器。
WITH C AS 
(
	SELECT *,
		ROW_NUMBER() OVER(PARTITION BY orderid
							ORDER BY (SELECT NULL)) AS n
		FROM Sales.MyOrders
)
SELECT orderid,custid,empid,orderdate,requireddate,shippeddate,
		shipperid,freight,shipname,shipaddress,shipcity,shipregion,
		shippostalcode,shipcountry
INTO Sale.OrdersTmp
FROM C
WHERE n =1;

DROP TABLE Sales.MyOrders;
EXEC sp_rename 'Sales.OrdersTmp','MyOrders';

其他方法，基于orderid 的顺序同时计算ROW_NUMBER 和 RANK
WITH C AS 
(
	SELECT orderid,
		ROW_NUMBER()OVER(ORDER BY orderid)AS rownum,
		RANK() OVER(ORDER BY orderid) AS rnk
	FROM Sales,MyOrders
)

DELETE FROM C
WHERE rownum<> rnk;

5.6 数据透视
	透视：一种通过聚合和旋转把数据行转换成数据列的技术。
	当透视数据时，需要确定3个要素，要在行(分组元素)中看到的元素，要在列(扩展元素)上看到的元素，
					要在数据部分看打破的元素(聚合元素)。

	eg：假设我们需要查询Sales.OrderValues视图，并为每个订单年返回一行，每个订单月返回一行，
	年份和月份相交的每一个地方是订单金额总和。
	基于此请求，行或分组的元素是YEAR(orderdate);列或展开的元素是MONTH(orderdate);
	唯一扩展值是 1————12；数据或聚合的元素为SUM(val)。

	WITH C AS 
	(
		SELECT YEAR(orderdate) AS orderyear,MONTH(orderdate) AS ordermonth,val
		FROM Sales.OrderValues
	)
	SELECT *
	FROM C 
		PIVOT(SUM(val)
			FOR ordermonth IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])) AS P;

orderyear   1                                       2                                       3                                       4                                       5                                       6                                       7                                       8                                       9                                       10                                      11                                      12
----------- --------------------------------------- --------------------------------------- --------------------------------------- --------------------------------------- --------------------------------------- --------------------------------------- --------------------------------------- --------------------------------------- --------------------------------------- --------------------------------------- --------------------------------------- ---------------------------------------
2007        61258.08                                38483.64                                38547.23                                53032.95                                53781.30                                36362.82                                51020.86                                47287.68                                55629.27                                66749.23                                43533.80                                71398.44
2008        94222.12                                99415.29                                104854.18                               123798.70                               18333.64                                NULL                                    NULL                                    NULL                                    NULL                                    NULL                                    NULL                                    NULL
2006        NULL                                    NULL                                    NULL                                    NULL                                    NULL                                    NULL                                    27861.90                                25485.28                                26381.40                                37515.73                                45600.05                                45239.63

扩展元素不存在于源数据中
eg：为每一个客户返回最近5次订单的订单ID,希望在不同客户的订单上看到客户ID,在数据部分看到订单ID,但是
不同客户的订单ID之间没有共同点用来作为扩展元素
	解决方案是使用ROW_NUMBER 函数为每个客户分区内的订单分配序号
WITH C AS 
(
	SELECT custid,val,ROW_NUMBER() OVER(PARTITION BY custid
										ORDER BY orderdate DESC,orderid DESC) AS rownum
	FROM Sales.OrderValues
)

SELECT *
FROM C 
	PIVOT(MAX(val) FOR rownum IN ([1],[2],[3],[4],[5]))AS P;

custid      1                                       2                                       3                                       4                                       5
----------- --------------------------------------- --------------------------------------- --------------------------------------- --------------------------------------- ---------------------------------------
1           933.50                                  471.20                                  845.80                                  330.00                                  878.00
2           514.40                                  320.00                                  479.75                                  88.80                                   NULL
3           660.00                                  375.50                                  813.37                                  2082.00                                 1940.85
4           491.50                                  4441.25                                 390.00                                  282.00                                  191.10


5.7 每组前N行

当需要从每个组或分区中根据某中指定排序筛选出一定数量的行。

无论使用什么策略，都以POC理念
CREATE UNIQUE INDEX idx_cid_odDDD_oidD_i_empid
	ON Sales.Orders(custid,orderdate DESC,orderid DESC)
	INCLUDE(empid);

策略一使用ROW_NUMBER函数；而另一种使用APPLY运算符和OFFSET/FETCH或TOP.
采用哪一种策略由分区的密度决定
	低密度——意味着有大量不同的客户，每个客户的订单都很小——基于ROW_NUMBER函数的解决方案最佳
	WITH C AS 
	(
		SELECT custid,orderdate,orderid,empid,
		ROW_NUMBER() OVER(PARTITION BY custid
							ORDER BY orderdate DESC,orderid DESC )AS rownum
		FROM Sales.Orders
	)
	SELECT *
	FROM C
	WHERE rownum <=3
	ORDER BY custid,rownum;

当分区列值具有高密度时(少量不同的客户，每一个客户都有大量订单)，在索引上为每个客户执行查询，
SELECT C.custid,A.*
FROM Sales.Customers AS C
	CROSS APPLY (SELECT orderdate,orderid,empid
					FROM Sales.Orders AS O
					WHERE O.custid = C.custid
					ORDER BY orderdate DESC,orderid DESC
					OFFSET 0 ROWS FETCH FIRST 3 ROWS ONLY) AS A;


如果没有POC索引
	WITH C AS 
	(
		SELECT custid,
			MAX(CONVERT(CHAR(8),orderdate,112)
				+ STR(orderid,10)
				+ STR(empid,10)COLLATE Latinl_General_BIN2)AS mx
		FROM Sales.Orders
		Group BY custid 
	)
	SELECT custid,
		CAST(SUBSTRING(mx,1,8)AS DATETIME) AS orderdate,
		CAST(SUBSTRING(mx,9,10)AS INT)     AS custid,
		CAST(SUBSTRING(mx,19,10)AS INT)    AS empid
	FROM C;

5.8 模式
	模式：返回在全体中频繁出现个例的统计计算。
	例如：Sales.Orders表保存订单信息，每个订单都是由某客户下单，并且都被某个员工处理过。
	对于每一个客户，假设哪个员工处理了最多的订单，该员工就是模式，因为她对客户的订单来说出现得最频繁。

第一步基于custid和empid对订单分组，然后返回每组的订单数

SELECT custid,empid,COUNT(*) AS cnt
FROM Sales.Orders
GROUP BY custid,empid;

custid      empid       cnt
----------- ----------- -----------
1           1           2
3           1           1
4           1           3
5           1           4
9           1           3
10          1           2
11          1           1
14          1           1
15          1           1

第二步： 基于custid分区，通过COUNT(*) DESC、empid DESC 排序。
分配行号1给每个具有最高计数行的客户(在并列的情况下，选择雇员ID最高的)：

SELECT custid,empid,COUNT(*) AS cnt,
	ROW_NUMBER()OVER(PARTITION BY custid ORDER BY COUNT(*) DESC,empid DESC) AS rn
FROM Sales.Orders
GROUP BY custid,empid;

custid      empid       cnt         rn
----------- ----------- ----------- --------------------
1           4           2           1
1           1           2           2
1           6           1           3
1           3           1           4
2           3           2           1
2           7           1           2
2           4           1           3
3           3           3           1
3           7           2           2
3           4           1           3

最后利用CTE筛选楚行号等于1的行

WITH C AS
(
	SELECT custid,empid,COUNT(*)AS cnt,
	ROW_NUMBER() OVER (PARTITION BY custid
						ORDER BY COUNT(*) DESC , empid DESC) AS rn
	FROM Sales.Orders
	GROUP BY custid,empid
)
SELECT custid,empid,cnt
FROM C
WHERE rn = 1;

custid      empid       cnt
----------- ----------- -----------
1           4           2
2           3           2
3           3           3
4           4           4
5           3           6
6           9           3
7           4           3
8           4           2
9           4           4
10          3           4

因为窗口排序empid DESC作为决胜点，如果不想打破平手，可以使用RANK函数，而不是ROW_NUMBER,并从窗口排序
子句中删除empid,如下所示
WITH C AS
(
	SELECT custid,empid,COUNT(*)AS cnt,
	RANK() OVER (PARTITION BY custid
						ORDER BY COUNT(*) DESC) AS rn
	FROM Sales.Orders
	GROUP BY custid,empid
)
SELECT custid,empid,cnt
FROM C
WHERE rn = 1;

custid      empid       cnt
----------- ----------- -----------
1           1           2
1           4           2
2           3           2
3           3           3
4           4           4
5           3           6
6           9           3
7           4           3
8           4           2
9           4           4
10          3           4

5.9 统计总和

应用场景： 计算银行账户余额，跟踪仓库中产品的库存水平，跟踪累积销售额

5.9.1 利用窗口函数的基于集合的解决方案
计算银行账户余额

SELECT actid,traind,val,
	SUM(val) OVER (PARTITION BY actid
					ORDER BY traind
					ROWS BETWEEN UNBOUNDED PRECEDING
						AND CURRENT ROW) AS balance
FROM dbo.Transactions;


5.10 最大并发间隔
	5.10.3 基于窗口函数的解决方案
	WITH C1 AS 
	(
		SELECT app,starttime AS ts, +1 AS type
		FROM dbo.Session

		UNION ALL

		SELECT app,endtime,-1
		FROM dbo.Sessions
	),
	C2 AS 
	(
		SELECT *,
			SUM(type) OVER( PARTITION BY app ORDER BY ts,type
								ROWS BETWEEN UNBOUNDED PERCEDING AND CURRENT ROW) AS cnt
		FROM C1
	)
	SELECT app, MAX(cnt) AS mx
	FROM C2
	GROUP BY app;

5.11 包装间隔(Packing interval)
	就是对每组联系的间隔进行分组，增加没有其他的间隔重叠或相邻（对接），并返回每组的最早开始时间和最迟
结束时间

5.11.1 传统的基于集合的解决方案

WITH Starttime AS 
(
	SELECT DISTINCT username,starttime
	FORM dbo.Sessions AS S1
	WHERE NOT EXISTS	
		(
			SELECT * FROM dbo.Sessions AS S2
			WHERE S2.username = S1.username
				AND S2.starttime < S1.starttime
				AND S2.endtime >= S1.starttime
		)

),
EndTimes AS
(
	SELECT DISTINCT username,endtime
	FROM dbo.Sessions AS S1
	WHERE NOT EXISTS
		(
			SELECT * FROM dbo.Sessions AS S2
			WHERE S2.username = S1.username
				AND S2.endtime > S1.endtime
				AND S2.starttime <= S1.endtime
		)
)

SELECT username,starttime,
	(SELECT MIN(endtime) FROM EndTimes AS E
		WHERE E.uername = S.username
			AND endtime >= starttime) AS endtime
FROM StartTimes AS S;

5.11.2 基于窗口函数的解决方案

TODO 


5.12 数据差距和数据岛
	基本概念：我们有一些数字、日期或时间值序列，其中的序列值之间应该是有固定
的间隔，但有些序列值可能会丢失。


5.12.1 数据差距
	

	


5.12.2 数据岛

5.12.3 中位数




5.13 条件聚合

5.14 层次结构排序












