
%% I. 清空环境变量
clear all
clc
%% II. 导入数据
attributes=xlsread('C:\Users\ZTY0918\Desktop\元素.xlsx')';
%attributes=xlsread('C:\Users\ZTY0918\Desktop\C的预测因素.xlsx')';
strength=xlsread('C:\Users\ZTY0918\Desktop\C吸收率.xlsx')';
Max1=0;
R2=0;
avg1=0;
sum1=0;
for o=1:20
    %%
    % 1. 随机产生训练集和测试集
    n = randperm(size(attributes,2));

    %%
    % 2. 训练集――800个样本
    p_train = attributes(:,n(1:800))';
    t_train = strength(:,n(1:800))';

    %%
    % 3. 测试集――162个样本
    p_test = attributes(:,n(801:end))';
    t_test = strength(:,n(801:end))';

    %% III. 数据归一化
    %%
    % 1. 训练集
    [pn_train,inputps] = mapminmax(p_train');
    pn_train = pn_train';
    pn_test = mapminmax('apply',p_test',inputps);
    pn_test = pn_test';

    %%
    % 2. 测试集
    [tn_train,outputps] = mapminmax(t_train');
    tn_train = tn_train';
    tn_test = mapminmax('apply',t_test',outputps);
    tn_test = tn_test';

    

    %% VII. BP神经网络
    %%
    % 1. 数据转置
    pn_train = pn_train';
    tn_train = tn_train';
    pn_test = pn_test';
    tn_test = tn_test';

    %[p1,minp,maxp,t1,mint,maxt]=premnmx(pn_train,tn_train);
    %%
    % 2. 创建BP神经网络
    %net=newff(minmax(pn_train),[16,10,2],{'tansig','tansig','purelin'},'trainlm');
    net = newff(pn_train,tn_train,10);

    %%
    % 3. 设置训练参数
    net.trainParam.epochs = 1000;
    net.trainParam.goal = 1e-3;
    net.trainParam.show = 10;
    net.trainParam.lr = 0.1;

    %%
    % 4. 训练网络
    %[net,tr]=train(net,p1,t1);
    net = train(net,pn_train,tn_train);

    %%
    % 5. 仿真测试
    tn_sim = sim(net,pn_test);

    %%
    % 6. 均方误差
    E = mse(tn_sim - tn_test);

    %%
    % 7. 决定系数
    N = size(t_test,1);
    R2=(N.*sum(tn_sim.*tn_test)-sum(tn_sim).*sum(tn_test)).^2/((N.*sum((tn_sim).^2)-(sum(tn_sim)).^2).*(N.*sum((tn_test).^2)-(sum(tn_test)).^2)); 
 if (R2>Max1)
        Max1=R2;
    end
    sum1=sum1+R2;
%     if (R2>0.9)
%         break;
%     end
end
 avg1=sum1/20
%%
% 8. 反归一化
t_sim = mapminmax('reverse',tn_sim,outputps);
 
%%
% 9. 绘图
figure(3)
plot(1:length(t_test),t_test,'r-*',1:length(t_test),t_sim,'b:o')
grid on
legend('真实值','预测值')
xlabel('样本编号')
ylabel('耐压强度')
string_3 = {'测试集预测结果对比(BP神经网络)';
           ['mse = ' num2str(E) ' R^2 = ' num2str(R2)]};
title(string_3)