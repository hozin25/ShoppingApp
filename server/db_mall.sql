/*
SQLyog Community v13.2.0 (64 bit)
MySQL - 5.7.18-log : Database - db_mall
*********************************************************************
*/

/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
CREATE DATABASE /*!32312 IF NOT EXISTS*/`db_mall` /*!40100 DEFAULT CHARACTER SET utf8 */;

USE `db_mall`;

/*Table structure for table `address` */

DROP TABLE IF EXISTS `address`;

CREATE TABLE `address` (
  `id` int(20) NOT NULL AUTO_INCREMENT COMMENT '主键 ',
  `yonghu_id` int(20) NOT NULL COMMENT '创建用户',
  `address_name` varchar(200) NOT NULL COMMENT '收货人 ',
  `address_phone` varchar(200) NOT NULL COMMENT '电话 ',
  `address_dizhi` varchar(200) NOT NULL COMMENT '地址 ',
  `isdefault_types` int(11) NOT NULL COMMENT '是否默认地址 ',
  `insert_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '添加时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '修改时间',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间 show3',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8 COMMENT='收货地址';

/*Data for the table `address` */

insert  into `address`(`id`,`yonghu_id`,`address_name`,`address_phone`,`address_dizhi`,`isdefault_types`,`insert_time`,`update_time`,`create_time`) values 
(1,3,'收货人1','17703786901','地址1',1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(2,1,'收货人2','17703786902','地址2',1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(3,1,'收货人3','17703786903','地址3',1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(4,1,'收货人4','17703786904','地址4',1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(5,3,'收货人5','17703786905','地址5',1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(6,3,'收货人6','17703786906','地址6',1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(7,3,'收货人7','17703786907','地址7',1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(8,2,'收货人8','17703786908','地址8',1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(9,1,'收货人9','17703786909','地址9',1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(10,2,'收货人10','17703786910','地址10',1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(11,1,'收货人11','17703786911','地址11',1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(12,1,'收货人12','17703786912','地址12',1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(13,3,'收货人13','17703786913','地址13',1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(14,3,'收货人14','17703786914','地址14',1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40');

/*Table structure for table `cart` */

DROP TABLE IF EXISTS `cart`;

CREATE TABLE `cart` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `yonghu_id` int(11) DEFAULT NULL COMMENT '所属用户',
  `shangpin_id` int(11) DEFAULT NULL COMMENT '商品',
  `buy_number` int(11) DEFAULT NULL COMMENT '购买数量',
  `create_time` timestamp NULL DEFAULT NULL COMMENT '添加时间',
  `update_time` timestamp NULL DEFAULT NULL COMMENT '更新时间',
  `insert_time` timestamp NULL DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8 COMMENT='购物车';

/*Data for the table `cart` */

/*Table structure for table `chat` */

DROP TABLE IF EXISTS `chat`;

CREATE TABLE `chat` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `yonghu_id` int(11) DEFAULT NULL COMMENT '提问用户',
  `chat_issue` varchar(200) DEFAULT NULL COMMENT '问题',
  `issue_time` timestamp NULL DEFAULT NULL COMMENT '问题时间 Search111',
  `chat_reply` varchar(200) DEFAULT NULL COMMENT '回复',
  `reply_time` timestamp NULL DEFAULT NULL COMMENT '回复时间 Search111',
  `zhuangtai_types` int(255) DEFAULT NULL COMMENT '状态',
  `chat_types` int(11) DEFAULT NULL COMMENT '数据类型',
  `insert_time` timestamp NULL DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COMMENT='在线客服';

/*Data for the table `chat` */

insert  into `chat`(`id`,`yonghu_id`,`chat_issue`,`issue_time`,`chat_reply`,`reply_time`,`zhuangtai_types`,`chat_types`,`insert_time`) values 
(1,1,'123123','2025-03-29 10:49:35',NULL,NULL,2,1,'2025-03-29 10:49:35'),
(2,1,NULL,NULL,'1112312','2025-03-29 10:49:56',NULL,2,'2025-03-29 10:49:57'),
(3,1,'33322111','2025-03-29 10:50:33',NULL,NULL,1,1,'2025-03-29 10:50:33');

/*Table structure for table `config` */

DROP TABLE IF EXISTS `config`;

CREATE TABLE `config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(100) DEFAULT NULL COMMENT '配置参数名称',
  `value` varchar(100) DEFAULT NULL COMMENT '配置参数值',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COMMENT='配置文件';

/*Data for the table `config` */

insert  into `config`(`id`,`name`,`value`) values 
(1,'轮播图1','upload/config1.jpg'),
(2,'轮播图2','upload/config2.jpg'),
(3,'轮播图3','upload/config3.jpg');

/*Table structure for table `dictionary` */

DROP TABLE IF EXISTS `dictionary`;

CREATE TABLE `dictionary` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `dic_code` varchar(200) DEFAULT NULL COMMENT '字段',
  `dic_name` varchar(200) DEFAULT NULL COMMENT '字段名',
  `code_index` int(11) DEFAULT NULL COMMENT '编码',
  `index_name` varchar(200) DEFAULT NULL COMMENT '编码名字  Search111 ',
  `super_id` int(11) DEFAULT NULL COMMENT '父字段id',
  `beizhu` varchar(200) DEFAULT NULL COMMENT '备注',
  `create_time` timestamp NULL DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=65 DEFAULT CHARSET=utf8 COMMENT='字典';

/*Data for the table `dictionary` */

insert  into `dictionary`(`id`,`dic_code`,`dic_name`,`code_index`,`index_name`,`super_id`,`beizhu`,`create_time`) values 
(38,'shangjia_types','商家类型',1,'商家类型1',NULL,NULL,'2025-03-29 10:05:26'),
(39,'shangjia_types','商家类型',2,'商家类型2',NULL,NULL,'2025-03-29 10:05:26'),
(40,'shangjia_types','商家类型',3,'商家类型3',NULL,NULL,'2025-03-29 10:05:26'),
(41,'shangxia_types','上下架',1,'上架',NULL,NULL,'2025-03-29 10:05:26'),
(42,'shangxia_types','上下架',2,'下架',NULL,NULL,'2025-03-29 10:05:26'),
(43,'shangpin_types','商品类型',1,'商品类型1',NULL,NULL,'2025-03-29 10:05:26'),
(44,'shangpin_types','商品类型',2,'商品类型2',NULL,NULL,'2025-03-29 10:05:26'),
(45,'shangpin_types','商品类型',3,'商品类型3',NULL,NULL,'2025-03-29 10:05:26'),
(46,'shangpin_collection_types','收藏表类型',1,'收藏',NULL,NULL,'2025-03-29 10:05:27'),
(47,'shangpin_order_types','订单类型',101,'已支付',NULL,NULL,'2025-03-29 10:05:27'),
(48,'shangpin_order_types','订单类型',102,'已退款',NULL,NULL,'2025-03-29 10:05:27'),
(49,'shangpin_order_types','订单类型',103,'已发货',NULL,NULL,'2025-03-29 10:05:27'),
(50,'shangpin_order_types','订单类型',104,'已收货',NULL,NULL,'2025-03-29 10:05:27'),
(51,'shangpin_order_types','订单类型',105,'已评价',NULL,NULL,'2025-03-29 10:05:27'),
(52,'shangpin_order_payment_types','订单支付类型',1,'余额',NULL,NULL,'2025-03-29 10:05:27'),
(53,'isdefault_types','是否默认地址',1,'否',NULL,NULL,'2025-03-29 10:05:27'),
(54,'isdefault_types','是否默认地址',2,'是',NULL,NULL,'2025-03-29 10:05:27'),
(55,'news_types','公告类型',1,'公告类型1',NULL,NULL,'2025-03-29 10:05:27'),
(56,'news_types','公告类型',2,'公告类型2',NULL,NULL,'2025-03-29 10:05:27'),
(57,'sex_types','性别类型',1,'男',NULL,NULL,'2025-03-29 10:05:27'),
(58,'sex_types','性别类型',2,'女',NULL,NULL,'2025-03-29 10:05:27'),
(59,'chat_types','数据类型',1,'问题',NULL,NULL,'2025-03-29 10:05:27'),
(60,'chat_types','数据类型',2,'回复',NULL,NULL,'2025-03-29 10:05:27'),
(61,'zhuangtai_types','状态',1,'未回复',NULL,NULL,'2025-03-29 10:05:27'),
(62,'zhuangtai_types','状态',2,'已回复',NULL,NULL,'2025-03-29 10:05:27'),
(63,'forum_state_types','帖子状态',1,'发帖',NULL,NULL,'2025-03-29 10:05:27'),
(64,'forum_state_types','帖子状态',2,'回帖',NULL,NULL,'2025-03-29 10:05:27');

/*Table structure for table `forum` */

DROP TABLE IF EXISTS `forum`;

CREATE TABLE `forum` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `forum_name` varchar(200) DEFAULT NULL COMMENT '帖子标题  Search111 ',
  `yonghu_id` int(11) DEFAULT NULL COMMENT '用户',
  `shangjia_id` int(11) DEFAULT NULL COMMENT '商家',
  `users_id` int(11) DEFAULT NULL COMMENT '管理员',
  `forum_content` longtext COMMENT '发布内容',
  `super_ids` int(11) DEFAULT NULL COMMENT '父id',
  `forum_state_types` int(11) DEFAULT NULL COMMENT '帖子状态',
  `insert_time` timestamp NULL DEFAULT NULL COMMENT '发帖时间',
  `update_time` timestamp NULL DEFAULT NULL COMMENT '修改时间',
  `create_time` timestamp NULL DEFAULT NULL COMMENT '创建时间 show2',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8 COMMENT='论坛';

/*Data for the table `forum` */

insert  into `forum`(`id`,`forum_name`,`yonghu_id`,`shangjia_id`,`users_id`,`forum_content`,`super_ids`,`forum_state_types`,`insert_time`,`update_time`,`create_time`) values 
(1,'帖子标题1',2,NULL,NULL,'发布内容1',113,1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(2,'帖子标题2',2,NULL,NULL,'发布内容2',344,1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(3,'帖子标题3',1,NULL,NULL,'发布内容3',473,1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(4,'帖子标题4',3,NULL,NULL,'发布内容4',164,1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(5,'帖子标题5',3,NULL,NULL,'发布内容5',400,1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(6,'帖子标题6',2,NULL,NULL,'发布内容6',60,1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(7,'帖子标题7',3,NULL,NULL,'发布内容7',125,1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(8,'帖子标题8',2,NULL,NULL,'发布内容8',479,1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(9,'帖子标题9',1,NULL,NULL,'发布内容9',443,1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(10,'帖子标题10',2,NULL,NULL,'发布内容10',262,1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(11,'帖子标题11',1,NULL,NULL,'发布内容11',209,1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(12,'帖子标题12',3,NULL,NULL,'发布内容12',110,1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(13,'帖子标题13',1,NULL,NULL,'发布内容13',46,1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(14,'帖子标题14',3,NULL,NULL,'发布内容14',146,1,'2025-03-29 10:05:40','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(15,NULL,NULL,1,NULL,'123123123',14,2,'2025-03-29 10:45:51',NULL,'2025-03-29 10:45:51'),
(16,NULL,1,NULL,NULL,'123123',14,2,'2025-03-29 10:51:09',NULL,'2025-03-29 10:51:09');

/*Table structure for table `news` */

DROP TABLE IF EXISTS `news`;

CREATE TABLE `news` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `news_name` varchar(200) DEFAULT NULL COMMENT '公告标题  Search111 ',
  `news_types` int(11) DEFAULT NULL COMMENT '公告类型  Search111 ',
  `news_photo` varchar(200) DEFAULT NULL COMMENT '公告图片',
  `insert_time` timestamp NULL DEFAULT NULL COMMENT '添加时间',
  `news_content` longtext COMMENT '公告详情',
  `create_time` timestamp NULL DEFAULT NULL COMMENT '创建时间 show1 show2 nameShow',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8 COMMENT='公告信息';

/*Data for the table `news` */

insert  into `news`(`id`,`news_name`,`news_types`,`news_photo`,`insert_time`,`news_content`,`create_time`) values 
(1,'公告标题1',2,'upload/news1.jpg','2025-03-29 10:05:40','公告详情1','2025-03-29 10:05:40'),
(2,'公告标题2',1,'upload/news2.jpg','2025-03-29 10:05:40','公告详情2','2025-03-29 10:05:40'),
(3,'公告标题3',2,'upload/news3.jpg','2025-03-29 10:05:40','公告详情3','2025-03-29 10:05:40'),
(4,'公告标题4',1,'upload/news4.jpg','2025-03-29 10:05:40','公告详情4','2025-03-29 10:05:40'),
(5,'公告标题5',2,'upload/news5.jpg','2025-03-29 10:05:40','公告详情5','2025-03-29 10:05:40'),
(6,'公告标题6',1,'upload/news6.jpg','2025-03-29 10:05:40','公告详情6','2025-03-29 10:05:40'),
(7,'公告标题7',1,'upload/news7.jpg','2025-03-29 10:05:40','公告详情7','2025-03-29 10:05:40'),
(8,'公告标题8',2,'upload/news8.jpg','2025-03-29 10:05:40','公告详情8','2025-03-29 10:05:40'),
(9,'公告标题9',1,'upload/news9.jpg','2025-03-29 10:05:40','公告详情9','2025-03-29 10:05:40'),
(10,'公告标题10',2,'upload/news10.jpg','2025-03-29 10:05:40','公告详情10','2025-03-29 10:05:40'),
(11,'公告标题11',1,'upload/news11.jpg','2025-03-29 10:05:40','公告详情11','2025-03-29 10:05:40'),
(12,'公告标题12',1,'upload/news12.jpg','2025-03-29 10:05:40','公告详情12','2025-03-29 10:05:40'),
(13,'公告标题13',2,'upload/news13.jpg','2025-03-29 10:05:40','公告详情13','2025-03-29 10:05:40'),
(14,'公告标题14',1,'upload/news14.jpg','2025-03-29 10:05:40','公告详情14','2025-03-29 10:05:40');

/*Table structure for table `shangjia` */

DROP TABLE IF EXISTS `shangjia`;

CREATE TABLE `shangjia` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键 ',
  `username` varchar(200) DEFAULT NULL COMMENT '账户 ',
  `password` varchar(200) DEFAULT NULL COMMENT '密码 ',
  `shangjia_name` varchar(200) DEFAULT NULL COMMENT '商家名称 Search111 ',
  `shangjia_phone` varchar(200) DEFAULT NULL COMMENT '联系方式',
  `shangjia_email` varchar(200) DEFAULT NULL COMMENT '邮箱',
  `shangjia_photo` varchar(200) DEFAULT NULL COMMENT '营业执照展示 ',
  `shangjia_types` int(11) DEFAULT NULL COMMENT '商家类型',
  `new_money` decimal(10,2) DEFAULT NULL COMMENT '现有余额',
  `shangjia_content` longtext COMMENT '商家介绍 ',
  `shangjia_delete` int(11) DEFAULT NULL COMMENT '逻辑删除',
  `create_time` timestamp NULL DEFAULT NULL COMMENT '创建时间 show1 show2 photoShow ',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COMMENT='商家';

/*Data for the table `shangjia` */

insert  into `shangjia`(`id`,`username`,`password`,`shangjia_name`,`shangjia_phone`,`shangjia_email`,`shangjia_photo`,`shangjia_types`,`new_money`,`shangjia_content`,`shangjia_delete`,`create_time`) values 
(1,'a1','123456','商家名称1','17703786901','1@qq.com','upload/shangjia1.jpg',1,116.88,'<p>商家介绍1</p>',1,'2025-03-29 10:05:40'),
(2,'a2','123456','商家名称2','17703786902','2@qq.com','upload/shangjia2.jpg',3,791.07,'商家介绍2',1,'2025-03-29 10:05:40'),
(3,'a3','123456','商家名称3','17703786903','3@qq.com','upload/shangjia3.jpg',3,27.44,'商家介绍3',1,'2025-03-29 10:05:40');

/*Table structure for table `shangpin` */

DROP TABLE IF EXISTS `shangpin`;

CREATE TABLE `shangpin` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键 ',
  `shangjia_id` int(11) DEFAULT NULL COMMENT '商家',
  `shangpin_name` varchar(200) DEFAULT NULL COMMENT '商品名称  Search111 ',
  `shangpin_uuid_number` varchar(200) DEFAULT NULL COMMENT '商品编号',
  `shangpin_photo` varchar(200) DEFAULT NULL COMMENT '商品照片',
  `shangpin_types` int(11) DEFAULT NULL COMMENT '商品类型 Search111',
  `shangpin_kucun_number` int(11) DEFAULT NULL COMMENT '商品库存',
  `shangpin_old_money` decimal(10,2) DEFAULT NULL COMMENT '商品原价 ',
  `shangpin_new_money` decimal(10,2) DEFAULT NULL COMMENT '现价',
  `shangpin_clicknum` int(11) DEFAULT NULL COMMENT '商品热度',
  `shangpin_content` longtext COMMENT '商品介绍 ',
  `shangxia_types` int(11) DEFAULT NULL COMMENT '是否上架 ',
  `shangpin_delete` int(11) DEFAULT NULL COMMENT '逻辑删除',
  `insert_time` timestamp NULL DEFAULT NULL COMMENT '录入时间',
  `create_time` timestamp NULL DEFAULT NULL COMMENT '创建时间  show1 show2 photoShow',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8 COMMENT='商品';

/*Data for the table `shangpin` */

insert  into `shangpin`(`id`,`shangjia_id`,`shangpin_name`,`shangpin_uuid_number`,`shangpin_photo`,`shangpin_types`,`shangpin_kucun_number`,`shangpin_old_money`,`shangpin_new_money`,`shangpin_clicknum`,`shangpin_content`,`shangxia_types`,`shangpin_delete`,`insert_time`,`create_time`) values 
(1,1,'商品名称1','1680055540131','upload/shangpin1.jpg',1,101,947.95,66.82,110,'商品介绍1',1,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(2,3,'商品名称2','1680055540125','upload/shangpin2.jpg',1,102,536.99,380.24,357,'商品介绍2',1,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(3,1,'商品名称3','1680055540067','upload/shangpin3.jpg',2,103,859.16,163.53,497,'商品介绍3',1,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(4,3,'商品名称4','1680055540053','upload/shangpin4.jpg',1,104,569.50,194.33,268,'商品介绍4',1,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(5,2,'商品名称5','1680055540102','upload/shangpin5.jpg',3,105,998.01,433.64,422,'商品介绍5',1,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(6,1,'商品名称6','1680055540069','upload/shangpin6.jpg',1,106,957.55,209.10,280,'商品介绍6',1,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(7,2,'商品名称7','1680055540140','upload/shangpin7.jpg',1,107,516.18,437.61,34,'商品介绍7',1,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(8,2,'商品名称8','1680055540050','upload/shangpin8.jpg',2,107,548.06,391.56,186,'商品介绍8',1,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(9,3,'商品名称9','1680055540131','upload/shangpin9.jpg',3,109,916.12,107.07,301,'商品介绍9',1,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(10,2,'商品名称10','1680055540067','upload/shangpin10.jpg',1,1010,669.34,406.87,36,'商品介绍10',1,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(11,3,'商品名称11','1680055540120','upload/shangpin11.jpg',2,1011,717.16,27.28,198,'商品介绍11',1,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(12,1,'商品名称12','1680055540085','upload/shangpin12.jpg',2,1012,761.30,48.43,96,'商品介绍12',1,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(13,2,'商品名称13','1680055540085','upload/shangpin13.jpg',2,1012,856.92,308.93,24,'商品介绍13',1,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(14,1,'商品名称14','1680055540054','upload/shangpin14.jpg',3,1012,923.84,20.95,326,'商品介绍14',1,1,'2025-03-29 10:05:40','2025-03-29 10:05:40');

/*Table structure for table `shangpin_collection` */

DROP TABLE IF EXISTS `shangpin_collection`;

CREATE TABLE `shangpin_collection` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `shangpin_id` int(11) DEFAULT NULL COMMENT '商品',
  `yonghu_id` int(11) DEFAULT NULL COMMENT '用户',
  `shangpin_collection_types` int(11) DEFAULT NULL COMMENT '类型',
  `insert_time` timestamp NULL DEFAULT NULL COMMENT '收藏时间',
  `create_time` timestamp NULL DEFAULT NULL COMMENT '创建时间 show3 photoShow',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8 COMMENT='商品收藏';

/*Data for the table `shangpin_collection` */

insert  into `shangpin_collection`(`id`,`shangpin_id`,`yonghu_id`,`shangpin_collection_types`,`insert_time`,`create_time`) values 
(1,1,3,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(2,2,3,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(3,3,3,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(4,4,3,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(5,5,3,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(6,6,2,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(7,7,2,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(8,8,3,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(9,9,1,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(10,10,3,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(11,11,1,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(12,12,2,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(13,13,1,1,'2025-03-29 10:05:40','2025-03-29 10:05:40'),
(15,14,1,1,'2025-01-30 11:04:55','2025-01-30 11:04:55');

/*Table structure for table `shangpin_commentback` */

DROP TABLE IF EXISTS `shangpin_commentback`;

CREATE TABLE `shangpin_commentback` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `shangpin_id` int(11) DEFAULT NULL COMMENT '商品',
  `yonghu_id` int(11) DEFAULT NULL COMMENT '用户',
  `shangpin_commentback_text` longtext COMMENT '评价内容',
  `insert_time` timestamp NULL DEFAULT NULL COMMENT '评价时间',
  `reply_text` longtext COMMENT '回复内容',
  `update_time` timestamp NULL DEFAULT NULL COMMENT '回复时间',
  `create_time` timestamp NULL DEFAULT NULL COMMENT '创建时间 show3 listShow',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8 COMMENT='商品评价';

/*Data for the table `shangpin_commentback` */

insert  into `shangpin_commentback`(`id`,`shangpin_id`,`yonghu_id`,`shangpin_commentback_text`,`insert_time`,`reply_text`,`update_time`,`create_time`) values 
(1,1,1,'评价内容1','2025-03-29 10:05:40','回复信息1','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(2,2,1,'评价内容2','2025-03-29 10:05:40','回复信息2','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(3,3,1,'评价内容3','2025-03-29 10:05:40','回复信息3','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(4,4,3,'评价内容4','2025-03-29 10:05:40','回复信息4','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(5,5,1,'评价内容5','2025-03-29 10:05:40','回复信息5','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(6,6,2,'评价内容6','2025-03-29 10:05:40','回复信息6','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(7,7,2,'评价内容7','2025-03-29 10:05:40','回复信息7','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(8,8,1,'评价内容8','2025-03-29 10:05:40','回复信息8','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(9,9,1,'评价内容9','2025-03-29 10:05:40','回复信息9','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(10,10,1,'评价内容10','2025-03-29 10:05:40','回复信息10','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(11,11,1,'评价内容11','2025-03-29 10:05:40','回复信息11','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(12,12,1,'评价内容12','2025-03-29 10:05:40','回复信息12','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(13,13,2,'评价内容13','2025-03-29 10:05:40','回复信息13','2025-03-29 10:05:40','2025-03-29 10:05:40'),
(14,14,1,'评价内容14','2025-03-29 10:05:40','回复信息1411111','2025-03-29 10:45:24','2025-03-29 10:05:40'),
(15,14,1,'123123','2025-03-29 10:52:29',NULL,NULL,'2025-03-29 10:52:29');

/*Table structure for table `shangpin_order` */

DROP TABLE IF EXISTS `shangpin_order`;

CREATE TABLE `shangpin_order` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `shangpin_order_uuid_number` varchar(200) DEFAULT NULL COMMENT '订单号 Search111 ',
  `address_id` int(11) DEFAULT NULL COMMENT '收货地址 ',
  `shangpin_id` int(11) DEFAULT NULL COMMENT '商品',
  `yonghu_id` int(11) DEFAULT NULL COMMENT '用户',
  `buy_number` int(11) DEFAULT NULL COMMENT '购买数量',
  `shangpin_order_true_price` decimal(10,2) DEFAULT NULL COMMENT '实付价格',
  `shangpin_order_courier_name` varchar(200) DEFAULT NULL COMMENT '快递公司',
  `shangpin_order_courier_number` varchar(200) DEFAULT NULL COMMENT '订单快递单号',
  `shangpin_order_types` int(11) DEFAULT NULL COMMENT '订单类型 Search111 ',
  `shangpin_order_payment_types` int(11) DEFAULT NULL COMMENT '支付类型',
  `insert_time` timestamp NULL DEFAULT NULL COMMENT '订单创建时间',
  `create_time` timestamp NULL DEFAULT NULL COMMENT '创建时间 show3 listShow',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8 COMMENT='商品订单';

/*Data for the table `shangpin_order` */

insert  into `shangpin_order`(`id`,`shangpin_order_uuid_number`,`address_id`,`shangpin_id`,`yonghu_id`,`buy_number`,`shangpin_order_true_price`,`shangpin_order_courier_name`,`shangpin_order_courier_number`,`shangpin_order_types`,`shangpin_order_payment_types`,`insert_time`,`create_time`) values 
(1,'1680057527015',9,14,1,1,20.95,'JD','12312312312312312',105,1,'2025-03-29 10:38:47','2025-03-29 10:38:47'),
(2,'1680058340757',3,13,1,1,308.93,NULL,NULL,101,1,'2025-03-29 10:52:21','2025-03-29 10:52:21'),
(3,'1680058340757',3,14,1,1,20.95,NULL,NULL,102,1,'2025-03-29 10:52:21','2025-03-29 10:52:21'),
(4,'1738206316944',11,8,1,1,391.56,NULL,NULL,101,1,'2025-01-30 11:05:17','2025-01-30 11:05:17'),
(5,'1738206316944',11,14,1,1,20.95,NULL,NULL,101,1,'2025-01-30 11:05:17','2025-01-30 11:05:17');

/*Table structure for table `token` */

DROP TABLE IF EXISTS `token`;

CREATE TABLE `token` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `userid` bigint(20) NOT NULL COMMENT '用户id',
  `username` varchar(100) NOT NULL COMMENT '用户名',
  `tablename` varchar(100) DEFAULT NULL COMMENT '表名',
  `role` varchar(100) DEFAULT NULL COMMENT '角色',
  `token` varchar(200) NOT NULL COMMENT '密码',
  `addtime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '新增时间',
  `expiratedtime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '过期时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COMMENT='token表';

/*Data for the table `token` */

insert  into `token`(`id`,`userid`,`username`,`tablename`,`role`,`token`,`addtime`,`expiratedtime`) values 
(1,1,'a1','shangjia','商家','mq0c3o9siqxp6wjytgh1pozc5k22ew0l','2025-03-29 10:32:21','2025-03-29 11:45:04'),
(2,1,'admin','users','管理员','5i9r751afx93vj20ee6rmmpxtzpeg9kp','2025-03-29 10:32:27','2025-01-30 17:18:17'),
(3,1,'a1','yonghu','用户','nku7d8nvehynw4se3paz0cwvcwwhv9u4','2025-03-29 10:33:20','2025-01-30 12:18:17');

/*Table structure for table `users` */

DROP TABLE IF EXISTS `users`;

CREATE TABLE `users` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username` varchar(100) NOT NULL COMMENT '用户名',
  `password` varchar(100) NOT NULL COMMENT '密码',
  `role` varchar(100) DEFAULT '管理员' COMMENT '角色',
  `addtime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '新增时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COMMENT='管理员';

/*Data for the table `users` */

insert  into `users`(`id`,`username`,`password`,`role`,`addtime`) values 
(1,'java1234','123456','管理员','2025-03-29 10:05:26');

/*Table structure for table `yonghu` */

DROP TABLE IF EXISTS `yonghu`;

CREATE TABLE `yonghu` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username` varchar(200) DEFAULT NULL COMMENT '账户',
  `password` varchar(200) DEFAULT NULL COMMENT '密码',
  `yonghu_name` varchar(200) DEFAULT NULL COMMENT '用户姓名 Search111 ',
  `yonghu_phone` varchar(200) DEFAULT NULL COMMENT '联系方式',
  `yonghu_id_number` varchar(200) DEFAULT NULL COMMENT '身份证号',
  `yonghu_photo` varchar(200) DEFAULT NULL COMMENT '用户头像',
  `sex_types` int(11) DEFAULT NULL COMMENT '性别 Search111',
  `yonghu_email` varchar(200) DEFAULT NULL COMMENT '电子邮箱',
  `new_money` decimal(10,2) DEFAULT NULL COMMENT '余额 ',
  `create_time` timestamp NULL DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COMMENT='用户';

/*Data for the table `yonghu` */

insert  into `yonghu`(`id`,`username`,`password`,`yonghu_name`,`yonghu_phone`,`yonghu_id_number`,`yonghu_photo`,`sex_types`,`yonghu_email`,`new_money`,`create_time`) values 
(1,'a1','123456','用户姓名1','17703786901','410224199010102001','upload/yonghu1.jpg',1,'1@qq.com',9327.98,'2025-03-29 10:05:40'),
(2,'a2','123456','用户姓名2','17703786902','410224199010102002','upload/yonghu2.jpg',1,'2@qq.com',503.90,'2025-03-29 10:05:40'),
(3,'a3','123456','用户姓名3','17703786903','410224199010102003','upload/yonghu3.jpg',1,'3@qq.com',667.42,'2025-03-29 10:05:40');

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
