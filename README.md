# ysyx-sdb-tui

A simple tui used for sdb in the ysyx project's nemu or npc.

![Examples](image/example.png)

## 特点

- 低依赖，只需要按照极少依赖即可运行
- 模块化，独立模块，提供了对外的几个接口，只需要修改少量源码即可运行
- 高性能，此工具几乎不会影响你正常运行程序，唯一的损耗是程序在调试时需要添加 `-ggdb`和开启 `O1`优化

## 使用指南

以下均在 `Ubuntu 22.04` 环境下测试成功，其他版本未知。

### 实现方法

1. 编译AM程序的时候添加 `-ggdb`以增加调试信息
2. 使用Python解析ELF文件，并生成GDB命令列表文件
3. GDB执行命令并生成包含源码和反汇编代码信息的文件
4. 使用 `vim`的 `remote`功能创建vim服务器
5. NEMU在作为客户端给vim服务器发送命令并执行
6. NEMU通过让vim服务器加载vim脚本方式定位和高亮
7. （可选）使用 `tmux`所带来的福利自动分割和启动窗口

### 安装依赖

- `apt install vim-gtk`以使得 `vim`支持 `clientserver`，使用 `vim --version | grep clientserver` 查看是否有 `+clientserver`
- `apt install gdb-multiarch` 以支持RISC-V的 `gdb` 功能，注意，非Ubuntu用户可能使用其他的 `gdb` 工具链
- `pip(3) install pyelftools` 以使得Python可以解析ELF文件
- 其他依赖，欢迎补充

### NEMU

1. 将 `disasm-autojump.c` 和 `disasm-highlight.vim`放在NEMU的 `utils`目录下（放别的地方也可以，无影响）
2. 在 `Kconfig`合适的位置添加 `VIM_AUTO_JUMP`
3. 在 `init_monitor`函数的 `longimg_size=load_img();`之后合适的位置声明和调用 `disasm_init_vim_script(cpu.pc)`
4. 在 `execute`函数中的 `for` **循环体结束后**添加  `disasm_pos_and_hl(s.pc)`


> [!WARNING]
> $\color{red}{请不要}$把 `disasm_pos_and_hl()`函数放在 `trace_and_difftest` 中，这样会大量执行 `system()` ，这可能导致你的操作系统产生损坏！

### AM

1. `abstract-machine`添加`CFLAGS += -ggdb`和`GDB  = gdb-multiarch`，并且把`O2`改为`O1`，然后将AM目录下的所有`build`清除，重新编译
2. 在`nemu.mk`的`image:`下添加：
`GDB_CMD_LIST := $(AM_HOME)/tools/gdb-cmd.txt`
```makefile
	@$(OBJDUMP) -M no-aliases -d $(IMAGE).elf > $(IMAGE)-no-aliases.txt
# Only for debugging, close it in other cases
	@echo + GDB-GEN-TXT "->" ${IMAGE}-gdb-gen.txt
	@python3 ${AM_HOME}/tools/gdb-cmd-gen.py ${IMAGE}.elf ${GDB_CMD_LIST}

# We use a simple method to fix the '__am_asm_trap' symbol,
# but not all programs have this symbol.
# If you encounter and error here, ignore it.
	-@$(GDB) --batch -x ${GDB_CMD_LIST} > ${IMAGE}-gdb-gen.txt
```

### Tmux (optional)
关于tmux，你可以参考以下指令序列，加在Makefile合适的位置，也可以选择不管，这项内容还不是很完善。

```makefile
# If you don't run in tmux, the following code will not work.
ifneq ($(shell echo $$TMUX),)
	@tmux kill-pane -a
	@sleep 0.2
	@tmux split-window -h
	@sleep 0.2
	@tmux split-window -v
	@sleep 0.2
	@tmux swap-pane -s 0 -t 2
	@sleep 0.2
	@tmux send-keys "vim ${IMAGE}-gdb-gen.txt" C-m
	@sleep 0.2
	@tmux select-pane -t 1
	@sleep 0.2
	@tmux send-keys "touch build/nemu-log.txt" C-m
	@sleep 0.2
	@tmux send-keys "tail -f build/nemu-log.txt" C-m
	@sleep 0.2
	@tmux select-pane -t 2
	@sleep 0.2
endif
```

### 运行

我假设你没有使用上面的`tmux`脚本。
1. 使用`make ARCH=ISA`编译AM程序
2. 使用`vim --servername VIM YouFile`打开`build`目录下生成的gdb反汇编文件（启动vim服务器）
3. 使用`make ARCH=ISA run`运行你的程序（连接VIM服务器）

注意，如果你不小心同时打开了多个vim服务器，并且名字都为`VIM`，NEMU只会连接到第一个打开的名字为`VIM`的服务器，其他服务器的名字vim会自动为你改名，服务器的名称是唯一的，你可以使用`vim --serverlist`查看。

## 未来计划

该工具的设计充分遵循了UNIX设计哲学，更多的提供的是把这些工具联系起来的思路。

我们在AM的Python脚本中生成gdb指令，这意味着可以使用gdb的所有能力去生成想要的东西，而不需要自己再去解析调试信息了，然后修改NEMU的vim脚本做相关的匹配。

我们也可以配置更强大的vim，比如把vim打造为IDE，这一点网上有很多教程。然后可以为vim脚本添加更多功能，这样我们就可以更灵活地操作更多事情了。（vim脚本可能不那么友好，但是它支持调用python的，python在vim脚本内也可以使用vim库）

之后再为NEMU添加一些sdb指令，类似于gdb tui相关的指令，嗯……整体设想还是很美好的，其可行性和必要性还值得商榷，关键点在于vim本身只是文本编辑器，更多的是支持静态脚本，vim GUI和其命令执行是在一个线程，如果你运行一个动态脚本，会导致界面非常卡，以及vim服务器的通讯能力非常差，导致可做的扩展很少。

