# SpingMVC的实现原理 



​    springMVC有着强大的整合能力，其中Spring本身自带的` ` ApplicationConetext配置文件用于管理各类实例的生成，通过Bean文件的方式进行生成实例。

 

##### 简单的Spring框架

1、ApplicationConetext接口继承了多种BeanFactory的类，有着比BeanFactory更加强大的功能

```java
public interface ApplicationContext extends EnvironmentCapable, ListableBeanFactory, HierarchicalBeanFactory,
		MessageSource, ApplicationEventPublisher, ResourcePatternResolver
```



2、这是BeanFactory的其中的一个方法，便是用来实例化配置文件当中的<Bean>...</Bean>实现类的，通过其创造实例，通过对实现类的扫描进行创建

```java
public interface BeanFactory {
    ...<T> T getBean(String var1, Class<T> var2) throws BeansException;
...}
```



##### SpringMVC

在springMVC当中，配置文件会有这几种

```java
applicationContext-Dao.xml
applicationContext-service.xml
applicationContext-trans.xml
SpringMvc.xml
//外加上web应用的配置文件
web.xml
```

其中，某些映射作为spring的组件，不再通过bean的方式加入其中。



###### 一、将要实现的东西加入到Spring容器当中



1、动态代理模式（与Mybatis整合）,通过包扫描的方式进行映射，==相当于利用mapper映射文件自动生成了实现类，并将其也是以Bean标签的形式加入到spring的容器当中（推荐）

```java
    <bean class="org.mybatis.spring.mapper.MapperScannerConfigurer">
    <property name="basePackage" value="com.zhai.crm.mapper"></property>
    </bean>
```

2、普通包扫描,包内含有接口以及实现类，但是大量的crud的代码都要在类中去写

component：组件的意思

```java
 <context:component-scan base-package="com.zhai.crm.service"></context:component-scan>
```

3、直接配置bean文件，实现类直接加入到其中,手动实现sqlSessionFactory,    这个是与Mybatis整合才用到的sql，**如果没用就忽略掉**

```java
<bean class="com.zhai.mybatis.dao.impl.UserDaoImpl">
    <property name="sqlSessionFactory" ref="sqlSessionFactory"></property>
    </bean>
```



在包扫描的过程中，要把用到的包全部都扫面进来，如mapper、service、controller，**<u>需要配置所要扫描的东西</u>**

还有Spring的配置文件等一系列的东西

```java
    <!--配置controller的包扫描  扫描controller的包  加上这个控制器-->
    <context:component-scan base-package="com.zhai.crm.controller"></context:component-scan>

<!--配置视图解析器  增加网页链接的前缀和后缀，视图管理器用于分析网页，并返回网页视图的-->
    <bean class="org.springframework.web.servlet.view.InternalResourceViewResolver">
        <!--注意前面的斜杠////!!!!!   很多时候都是因为映射不成功而跳转失败的/WEB-INF/jsp/-->
        <property name="prefix" value="/WEB-INF/jsp/"></property>
        <property name="suffix" value=".jsp"></property>
    </bean>
    
        <!--&lt;!&ndash;全球事物异常处理&ndash;&gt;-->
   <bean class="com.zhai.springmvc.MyException.CustomerExceptionResolver"></bean>
   
        <!--&lt;!&ndash;配置多媒体处理&ndash;&gt;-->
    <bean id="multipartResolver" class="org.springframework.web.multipart.commons.CommonsMultipartResolver">
    <!--&lt;!&ndash;最大上传大小8m&ndash;&gt;-->
    <property name="maxUploadSize" value="8388608"></property>
    </bean>
    
        <!--<mvc:interceptors>-->
        <!--配置多个拦截器-->
        <!--<mvc:interceptor>-->
            <!--拦截所有请求，包括二级以上目录-->
            <!--<mvc:mapping path="/**"/>-->
            <!--<bean class="com.zhai.springmvc.interceptor.MyInterceptor"></bean>-->
        <!--</mvc:interceptor>-->

```



###### 二、web应用的配置文件

在web文件的配置过程当中，首先要有DispatcherServlet，这是用来生成WebApplicationContext的方法，利用属性contextConfigLocation，它是ApplicationContext的子类，如果要加载其他配置文件当中的信息，则对

 <param-name>contextConfigLocation</param-name>
            <param-value>classpath:SpringMvc.xml</param-value>进行修改即可

```xml
<servlet>
        <servlet-name>springmvc-web</servlet-name>
        <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
        <init-param>
            <param-name>contextConfigLocation</param-name>
            <param-value>classpath:SpringMvc.xml</param-value>
        </init-param>
    </servlet>
    <!--//dispatch的映射-->
    <servlet-mapping>
        <!--只要尾部为action的东西都是它的  进入到springmvc-->
        <servlet-name>springmvc-web</servlet-name>
        <url-pattern>*.action</url-pattern>
    </servlet-mapping>
```

其中DispatcherServlet实现的方法为：

```java
	protected void initStrategies(ApplicationContext context) {
		initMultipartResolver(context);
		initLocaleResolver(context);
		initThemeResolver(context);
		initHandlerMappings(context);
		initHandlerAdapters(context);
		initHandlerExceptionResolvers(context);
		initRequestToViewNameTranslator(context);
		initViewResolvers(context);
		initFlashMapManager(context);
	}
```

其自动进行初始化的工作。同时WebApplicationContext便对浏览器访问拦截提供支持





<u>**到了这里，我们需要了解这个WebApplicationConetext在哪里去实现的呢，我们并没有手动生成**</u>

其中在Controller以及Service当中对于Dao层类方法的使用便是其通过Spring进行类的创建的

```java
@Autowired
private BaseDictDao baseDictDao;
```

自动注入，当其扫描到注解@Autowired的时候便会去BeanFactory的工厂当中找到这个Bean类并进行自动配置

从而对类进行实现



###### 三、监听加载

**此外**

```xml
<!-- 使用监听器加载Spring配置文件 org.springframework.web.context.ContextLoaderListener
    这个类被定义为监听器，并读取在参数contextConfigLocation中定义的xml 文件，
    如果不设置contextConfigLocation的初始参数则默认会读取    WEB-INF路径下的 application.xml文件，
    如果需要自定义了另外的xml 则可以在contextConfigLocation下定义，ContextLoaderListener会读取这些XML文件并产生 WebApplicationContext对象，
    然后将这个对象放置在ServletContext的属性里，这样我们只要可以得到Servlet就可以得到WebApplicationContext对象，
    并利用这个对象访问spring 容器管理的bean。-->
    <listener>
        <listener-class>org.springframework.web.context.ContextLoaderListener</listener-class>
    </listener>

```

在程序运行一开始便监听开始加载  Application等等配置文件 



###### 四、整合

用来配置sql语句等等东西，与Mybatis整合

```java
 <bean id="sqlSessionFactory" class="org.mybatis.spring.SqlSessionFactoryBean">
        <!--加载配置文件  核心文件的路径  无论里面是否具有映射-->
        <property name="configLocation" value="classpath:SqlMapConfig.xml"></property>
        <!--加载数据源  就是数据库-->
        <property name="dataSource" ref="dataSource"></property>
        <!--别名包扫描  都是整合文件的jar包里面的-->
        <property name="typeAliasesPackage" value="classpath:com.zhai.crm.pojo"></property>
    </bean>

```







#   