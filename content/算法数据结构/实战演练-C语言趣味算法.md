---
title: "棋谱篇"
date: 2021-11-18
description: "算法数据结构 · C语言趣味算法"
lead: "C语言趣味算法"
disable_comments: false # Optional, disable Disqus comments if true
authorbox: true # Optional, enable authorbox for specific post
toc: true # Optional, enable Table of Contents for specific post
mathjax: true # Optional, enable MathJax for specific post
categories:
  - "算法数据结构"
tags:
  - "算法数据结构"

#draft: true
---
[◀ 返回](/算法数据结构/算法数据结构-棋谱篇/)
# 汉诺塔
汉诺塔问题是源于印度一个古老传说的益智玩具。大梵天创造世界的时候做了三根金刚石柱子，在一根柱子上从上往下按照大小顺序摞着64片黄金圆盘。大梵天命令婆罗门把圆盘从下面开始按大小顺序重新排在另一根柱子上。并且规定，在小圆盘上不能放大圆盘，在三根柱子之间一次只能移动一个圆盘。
```c
#include <stdio.h>

void move(char x, char y)
{
    static int cnt = 0;
    printf("%d %c => %c\n", ++cnt, x, y);
}

void hanno(int n, char a, char b, char c)
{
    if ( n == 1 )
        move(a, c);
    else {
        hanno(n-1, a, c, b);
        move(a, c);
        hanno(n-1, b, a, c);
    }
}

int main( void )
{
    hanno(3, 'A', 'B', 'C');
    return 0;
}
```
## 百鸡百钱
今有鸡翁一，值钱伍；鸡母一，值钱三；鸡鶵三，值钱一。凡百钱买鸡百只，问鸡翁、母、鶵各几何？
```c
#include <stdio.h>

int main( void )
{
    int x;
    int y;
    int z;

    for (x=0; x<=100; x++)
    {
        for (y=0; y<=100; y++)
        {
            z = 100-x-y;
            if (z%3==0 && 5*x+3*y+z/3==100)
            {
                printf("公鸡%d,母鸡%d,小鸡%d\n",
                    x, y, z);
            }
        }
    }

    return 0;
}
```
## 常胜将军
现有21根火柴，两人轮流取，每人每次可以取走1至4根，不可多取，也不能不取，谁取最后一楰火柴谁输。请编写一个程序进行人机对弈，要求人先取，计算机后取；计算机一方为“常胜将军”
```c
#include <stdio.h>

int main( void )
{
    int last = 21;
    int user;
    int computer;

    for ( ; ; ) {
        printf("还剩%d根火柴!\n", last);
        printf("用户取几根? ");
        scanf("%d", &user);
        if ( user<1 || user>4 || user>last)
            continue;
        printf("你取了%d根火柴!\n", user);
        last -= user;
        if ( last == 0) {
          printf("你取走了最后一支火柴,你失败!\n");
          break;
        }

        computer = 5 - user;
        printf("计算机取了%d根火柴!\n", computer);
        last -= computer;
    }

    return 0;
}

```
## 约瑟夫环
已知n个人（以编号1，2，3…n分别表示）围坐在一张圆桌周围。从编号为k的人开始报数，数到m的那个人出列；他的下一个人又从1开始报数，数到m的那个人又出列；依此规律重复下去，直到圆桌周围的人全部出列
```c
#include<stdio.h>
int main( void ) {
    int i = -1;
    int j = 0;
    int kill = 0; //跳海的人数，用于控制循环结束
    int a[8] = {1,2,3,4,5,6,7,8};

    while ( kill < 8 ) {

        //for用于找到第三个离开的人
        for (j=0; j<=2; ) {
            i = (i+1)%8; //让i在0-7之间找下一个
            if (a[i] != -1 )
                j++;
        }

        printf("%d ", a[i]);
        a[i] = -1; //离开后位置用-1表示
        kill ++; //跳海人数+1
    }
    printf("\n");

    return 0;
}
```
## 最大公约数
```c
#include <stdio.h>

int main( void )
{
    int m;
    int n;
    int r;

    printf("求最大公约数!\n");
    printf("请输入两个数:");
    scanf("%d%d", &m, &n);

    r = m%n;
    while ( r != 0 )
    {
        m = n;
        n = r;
        r = m%n;
    }

    printf("最大公约数是%d\n", n);

    return 0;
}
```
---
[◀ 返回](/算法数据结构/算法数据结构-棋谱篇/)

