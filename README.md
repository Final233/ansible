# ansible playbook
## this is ansible playbook
by Final

1、预环境处理
- 内核参数
- 设置系统 ulimits
- 时间同步
- 软件包下载
- 禁用SWAP
- 加载内核模块
- 日志去重
- 证书
	- ca
	- etcd
	- kube api
	- kube sche
	- kube proxy
	- admin 
- kubeconfig 生成 并分发
- kubectl 自动补全
2、etcd
- 创建证书并分发
- 分发二进制程序，服务脚本
- 启动服务
3、runtime
- 当k8s>=1.24时
	- docker
		- 创建证书并分发
		- 分发二进制程序，服务脚本
		- 启动服务
	- containerd
		- 创建证书并分发
		- 分发二进制程序，服务脚本
		- 启动服务
4、master
- 创建证书并分发
- 分发二进制程序，服务脚本
- 启动服务
kube-apiserver kube-controler-manager kube-proxy 
5、node
- 创建证书并分发
- 分发二进制程序，服务脚本
- 启动服务
kubelet kube-proxy
6、网络组件 flannet calico
- 创建证书并分发
- 分发二进制程序插件
- 使用yaml文件创建pod ds
7、coredns
8、node-local-dns
8、dashboard
9、ingress
10、promethues
11、Cilium 网络策略
12、nfs-provisioner	 存储类
13、Ceph 