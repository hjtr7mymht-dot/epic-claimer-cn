# 来源与版权

本仓库是部署配置与补丁，不是上游项目的分支。

上游：

- 项目：Free Games Claimer Remaster
- 作者：Paweł Adamiec (P-Adamiec)
- 地址：https://github.com/P-Adamiec/Free-Games-Claimer-Remaster
- 版本基线：v1.18
- 许可：GNU Affero General Public License v3.0

上游自身受 vogler/free-games-claimer 启发：

- https://github.com/vogler/free-games-claimer
- 许可：AGPL-3.0

本仓库内容：

- `patches/epic-cn-cloudflare.patch`：针对中国大陆网络下 Cloudflare Turnstile 导致页面渲染延迟的适配补丁
- `docker-compose.yml`、`.env.example`、`scripts/setup.sh`：部署文件
- `README.md`：说明文档

以上内容同样以 AGPL-3.0 发布（见 LICENSE）。运行本方案时，Docker 镜像与容器内的上游代码仍由上游项目提供并适用其许可。
