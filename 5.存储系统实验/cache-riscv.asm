# file：cache-riscv.asm
# This program accesses an array in ways that provide data about the cache parameters.
# 本程序通过RARS数据cache仿真插件和内存访问可视化插件
# 帮助读者理解cache参数对cache性能的影响
# 本汇编程序的功能可以参考以下C语言伪代码
#   int array[];			// 整型数据为4字节
#   for (k=0; k<repcount; k++) {	// repcount：总循环次数
#   // 访问数组元素，具体访问哪些数组元素取决于步长stepsize
#     for (index=0; index<arraysize; index+=stepsize) {
#       if(option==0)
#         array[index]=0;		// option=0：涉及一次主存写
#       else
#         array[index]=array[index]+1;  
#                      			// option=1：涉及两次主存访问，读写各一次
#     }
#   }
          .data
array:   .space    2048     	# array数组最大字节空间，请勿修改
          .text                 	# 代码段开始标志
#########################################################################
# 以下加粗数值参数，用户可以自行调整 
main:	li	a0, 256			# 数组实际字节大小（应是2的幂次方并小于或等于2048）
         	li	a1, 2			# stepsize（应是2的幂次方）
         	li	a2, 1			# repcount（循环次数，应该大于0）
         	li	a3, 1			# 访存方式：0 — option=0，1 — option=1  
#########################################################################
         	jal	accessWords		# lw/sw
         	jal	accessBytes		# lb/sb	
         	li	a7,10			# exit
         	ecall
# 代码中寄存器使用说明
#  a0 ：arraysize，数组实际字节大小
#  a1 ：stepsize，数组访问步长
#  a2 ：number of times to repeat，数组循环访问次数
#  a3 ：0(W)/1(RW)，访存方式
#  s0 ：moving array ptr，数组滑动指针
#  s1 ：array limit ptr，数组访问上界指针
accessWords:
			  la	s0, array		# 指针指向数组
			  add	s1, s0, a0		# 固定数组访问上界（指针）
			  slli	t1, a1, 2		# 乘以步长4
wordLoop:
			  beq	a3, zero,  wordZero
			  lw	t0, 0(s0)		# array[index/4]++
			  addi	t0, t0, 1
			  sw	t0, 0(s0)
			  j	wordCheck
wordZero:	
			  sw	zero,	0(s0)		# array[index/4]=0
wordCheck:
			  add	s0, s0, t1		# 指针递增
			  blt	s0,s1,wordLoop  	# 内循环结束？
			  addi	a2, a2, -1
			  bgtz	a2, accessWords     	# 外循环结束？
			  jr	ra
accessBytes:
			  la	s0, array	        # 指针指向数组
			  add	s1, s0, a0		# 固定数组访问上界（指针）
byteLoop:
			  beq	a3, zero,  byteZero
			  lbu	t0, 0(s0)		# array[index]++
			  addi	t0, t0, 1
			  sb	t0, 0(s0)
			  j	byteCheck
byteZero:	
			  sb	zero,  0(s0)	        # array[index]=0
byteCheck:
			  add	s0, s0, a1		# 指针递增
			  blt	s0,s1,byteLoop	 	# 内循环结束？
			  addi	a2, a2, -1
			  bgtz	a2, accessBytes	   	# 外循环结束？
			  jr	ra
