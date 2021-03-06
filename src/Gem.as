package  
{
import com.greensock.easing.Sine;
import com.greensock.TweenMax;
import data.GemVo;
import events.GemEvent;
import flash.events.EventDispatcher;
import flash.geom.Point;
import flash.utils.Dictionary;
import utils.ArrayUtil;
import utils.Random;
/**
 * ...宝石迷阵算法
 * @author Kanon
 */
public class Gem extends EventDispatcher
{
    //颜色种类
    private var totalColorType:uint;
    //行数
    private var rows:uint;
    //列数
    private var columns:uint;
    //默认相同数量
    private var minSameNum:uint;
    //宝石列表
    private var gemList:Array;
	//颜色列表
	private var colorList:Array;
    //宝石字典
    private var _gemDict:Dictionary;
    //横向间隔
    private var gapH:Number;
    //纵向间隔
    private var gapV:Number;
    //宝石宽度
    private var gemWidth:Number;
    //宝石高度
    private var gemHeight:Number;
    //起始位置x
    private var startX:Number;
    //起始位置y
    private var startY:Number;
	//当前点击的宝石数据
	private var curGVo:GemVo;
	//宝石被销毁事件
	private var gemRemoveEvent:GemEvent;
    //添加宝石事件
	private var gemAddEvent:GemEvent;
	//待销毁的相同颜色的数据列表
	private var sameColorList:Array;
    //下落宝石数组
    private var fallList:Array;
	//重力加速度
	private const g:Number = .9;
	//下落时的间隔
	private var fallGapV:Number;
    /**
     * @param	totalColorType      总的颜色类型
     * @param	rows                行数
     * @param	columns             列数
     * @param	gapH                横向间隔
     * @param	gapV                纵向间隔
     * @param	startX              起始位置x
     * @param	startY              起始位置y
     * @param	gemWidth            宝石宽度
     * @param	gemHeight           宝石高度
     * @param	minLinkNum          默认链接数量
     */
    public function Gem(totalColorType:uint, 
                        rows:uint, columns:uint, 
                        gapH:Number, gapV:Number, 
                        startX:Number, startY:Number, 
                        gemWidth:Number, gemHeight:Number,
                        minSameNum:uint = 3) 
    {
        this.totalColorType = totalColorType;
        this.rows = rows;
        this.columns = columns;
        this.gemWidth = gemWidth;
        this.gemHeight = gemHeight;
        this.startX = startX;
        this.startY = startY;
        this.gapH = gapH;
        this.gapV = gapV;
        this.minSameNum = minSameNum;
        this.initData();
        this.initEvent();
    }
    
    /**
     * 初始化事件
     */
    private function initEvent():void 
    {
		this.gemRemoveEvent = new GemEvent(GemEvent.REMOVE);
		this.gemAddEvent = new GemEvent(GemEvent.ADD_GEM);
    }
    
    /**
     * 初始化数据
     */
    private function initData():void
    {
		this.colorList = [];
		for (var i:int = 1; i <= this.totalColorType; i += 1)
			this.colorList.push(i);
		this.gemList = [];
        this.fallList = [];
        this._gemDict = new Dictionary();
        var gVo:GemVo;
        var color:int;
        var point:Point;
        for (var row:int = 0; row < this.rows; row += 1) 
        {
            this.gemList[row] = [];
            for (var column:int = 0; column < this.columns; column += 1) 
            {
                gVo = new GemVo();
                gVo.width = this.gemWidth;
                gVo.height = this.gemHeight;
                gVo.row = row;
                gVo.column = column;
                gVo.isInPosition = true;
                this.gemList[row][column] = gVo;
                this._gemDict[gVo] = gVo;
                //设置坐标位置
                point = this.getGemPos(row, column);
                gVo.x = point.x;
                gVo.y = point.y;
                if (row < this.minSameNum - 1 && 
					column < this.minSameNum - 1)
                {
                    //第一行 第一列
                    //随机任意颜色
                    gVo.color = this.randomColor();
                }
                else
                {
					if (row < this.minSameNum - 1 && 
						column >= this.minSameNum - 1)
					{
						//前2行 后2列
						color = this.getLeftVoColor(row, column);
                        //如果左边相邻有2个以上的相同颜色则不使用此颜色
						if (color == 0) gVo.color = this.randomColor();
						else gVo.color = this.randomColor(color);
					}
					else if (column < this.minSameNum - 1 && 
							 row >= this.minSameNum - 1)
					{
						//前2列 后2行
						color = this.getUpVoColor(row, column);
						if (color == 0) gVo.color = this.randomColor();
						else gVo.color = this.randomColor(color);
					}
					else
					{
						gVo.color = 0;
						//前2行 后2列
						var color1:int = this.getLeftVoColor(row, column);
						var color2:int = this.getUpVoColor(row, column);
						//根据前面相同颜色 生成不重复超过(this.minLinkNum - 1)次的颜色
						gVo.color = this.randomColor(color1, color2);
					}
                }
				if (!this.fallList[column]) this.fallList[column] = [];
            }
        }
		this.fallGapV = this.gapV * 2;
    }
    
    /**
     * 根据行和列获取宝石的坐标
     * @param	row         行数
     * @param	column      列数
     * @return  坐标
     */
    private function getGemPos(row:int, column:int):Point
    {
        return new Point(this.startX + column * (this.gemWidth + this.gapH),
                         this.startY + row * (this.gemHeight + this.gapV));
    }
    
    /**
     * 获取相邻左边超过默认链接数量的相同颜色数据的颜色
     * @param	curRow          当前行坐标
     * @param	curColumn       当前列坐标
     * @return  相邻的颜色类型，如果未超过则返回0
     */
    private function getLeftVoColor(curRow:int, curColumn:int):int
    {
		if (curColumn == 0) return 0;
		var color:int = 0;
		var prevGVo:GemVo;
		//相同颜色的数量
		var num:int = 0;
        for (var column:int = curColumn - 1; column >= curColumn - 2; column -= 1) 
        {
			prevGVo = this.gemList[curRow][column];
			if (color == 0) 
			{
				color = prevGVo.color;
			}
			else
			{
				if (color == prevGVo.color) num++;
				else break;
			}
		}
		if (num > 0) return color;
		return 0;
    }
	
	/**
	 * 获取相邻上边超过默认链接数量的相同颜色数据的颜色
	 * @param	curRow			当前行坐标
	 * @param	curColumn		当前列坐标
	 * @return  相邻的颜色类型，如果未超过则返回0
	 */
	private function getUpVoColor(curRow:int, curColumn:int):int
    {
		if (curRow < 2) return 0;
		var color:int = 0;
		var prevGVo:GemVo;
		//相同颜色的数量
		var num:int = 0;
		for (var row:int = curRow - 1; row >= curRow - 2; row -= 1) 
        {
			prevGVo = this.gemList[row][curColumn];
			if (color == 0) 
			{
				color = prevGVo.color;
			}
			else
			{
				if (color == prevGVo.color) num++;
				else break;
			}
		}
		if (num > 0) return color;
		return 0;
	}
    
    /**
	 * 获取相邻下边超过默认链接数量的相同颜色数据的颜色
	 * @param	curRow			当前行坐标
	 * @param	curColumn		当前列坐标
	 * @return  相邻的颜色类型，如果未超过则返回0
	 */
    private function getDownVoColor(curRow:int, curColumn:int):int
    {
        if (curRow >= this.rows - 2) return 0;
		var color:int = 0;
		var prevGVo:GemVo;
		//相同颜色的数量
		var num:int = 0;
		for (var row:int = curRow + 1; row <= curRow + 2; row += 1) 
        {
			prevGVo = this.gemList[row][curColumn];
			if (color == 0) 
			{
				color = prevGVo.color;
			}
			else
			{
				if (color == prevGVo.color) num++;
				else break;
			}
		}
		if (num > 0) return color;
		return 0;
    }
    
    /**
     * 获取当前左边横向上的相邻相同颜色的数量
     * @param	curRow              当前行坐标
     * @param	curColumn           当前列坐标
     * @param	color           	当前颜色
     * @return  相同颜色的数据列表
     */
    private function getLeftSameColorVoList(curRow:int, curColumn:int, color:int):Array
    {
        var arr:Array = [];
        if (curColumn == 0) return arr;
        var prevGVo:GemVo;
        for (var column:int = curColumn - 1; column >= 0; column -= 1) 
        {
            prevGVo = this.gemList[curRow][column];
            if (!prevGVo) break;
            if (!prevGVo.isInPosition) break;
            if (prevGVo.color == color) arr.push(prevGVo);
            else break;
        }
        return arr;
    }
		
	/**
	 * 获取当前右边横向上的相邻相同颜色的数量
	 * @param	curRow			当前行坐标
	 * @param	curColumn		当前列坐标
	 * @param	color			当前颜色
	 * @return	相同颜色的数据列表
	 */
	private function getRightSameColorVoList(curRow:int, curColumn:int, color:int):Array
    {
        var arr:Array = [];
		if (curColumn == this.columns - 1) return arr;
        var prevGVo:GemVo;
        for (var column:int = curColumn + 1; column < this.columns; column += 1) 
        {
            prevGVo = this.gemList[curRow][column];
            if (!prevGVo) break;
            if (!prevGVo.isInPosition) break;
            if (prevGVo.color == color) arr.push(prevGVo);
            else break;
        }
        return arr;
	}
	
	/**
	 * 获取当前上边纵向上的相邻相同颜色的数量
	 * @param	curRow			当前行坐标
	 * @param	curColumn		当前列坐标
	 * @param	color			当前颜色
	 * @return	相同颜色的数据列表
	 */
	private function getUpSameColorVoList(curRow:int, curColumn:int, color:int):Array
    {
        var arr:Array = [];
		if (curRow == 0) return arr;
        var prevGVo:GemVo;
        for (var row:int = curRow - 1; row >= 0; row -= 1) 
        {
            prevGVo = this.gemList[row][curColumn];
            if (!prevGVo) break;
            if (!prevGVo.isInPosition) break;
            if (prevGVo.color == color) arr.push(prevGVo);
            else break;
        }
        return arr;
	}
	
	/**
	 * 获取当前下边纵向上的相邻相同颜色的数量
	 * @param	curRow			当前行坐标
	 * @param	curColumn		当前列坐标
	 * @param	color			当前颜色
	 * @return	相同颜色的数据列表
	 */
	private function getDownSameColorVoList(curRow:int, curColumn:int, color:int):Array
    {
		var arr:Array = [];
		if (curRow == this.rows - 1) return arr;
        var prevGVo:GemVo;
        for (var row:int = curRow + 1; row < this.rows; row += 1) 
        {
            prevGVo = this.gemList[row][curColumn];
            if (!prevGVo) break;
            if (!prevGVo.isInPosition) break;
            if (prevGVo.color == color) arr.push(prevGVo);
            else break;
        }
        return arr;
	}
    
    /**
     * 根据位置获取宝石数据
     * @param	posX        x位置     
     * @param	posY        y位置
     * @return  宝石数据
     */
    private function getGemVoByPos(posX:Number, posY:Number):GemVo
    {
        var gVo:GemVo;
        for each (gVo in this._gemDict) 
        {
            if (posX >= gVo.x && posX < gVo.x + gVo.width  && 
                posY >= gVo.y && posY < gVo.y + gVo.height)
                return gVo;
        }
        return null;
    }
	
	/**
	 * 随机颜色
	 * @param	...args			忽略的颜色
	 * @return	选取的颜色
	 */
	private function randomColor(...args):int
	{
		if (!args || args.length == 0) return Random.randint(1, this.totalColorType);
		var colorArr:Array = ArrayUtil.cloneList(this.colorList);
		var length:int = args.length;
		var index:int;
		var color:int;
		for (var i:int = 0; i < length; i += 1) 
		{
			color = args[i];
			if (color == 0) continue;
			index = colorArr.indexOf(color);
			colorArr.splice(index, 1);
		}
		return Random.choice(colorArr);
	}
	
	/**
	 * 判断是否周围上下左右的宝石数据
	 * @param	curRow			当前行坐标
	 * @param	curColumn		当前列坐标
	 * @return	周围4个宝石数据列表
	 */
	private function getSelectRoundGem(curRow:int, curColumn:int):Array
	{
		var arr:Array = [];
		if (curRow > 0)
			arr.push(this.gemList[curRow - 1][curColumn]);
		if (curRow < this.rows - 1)
			arr.push(this.gemList[curRow + 1][curColumn]);
		if (curColumn > 0)
			arr.push(this.gemList[curRow][curColumn - 1]);
		if (curColumn < this.columns - 1)
			arr.push(this.gemList[curRow][curColumn + 1]);
		return arr;
	}
	
	/**
	 * 判断2个宝石数据是否相同
	 * @param	gVo1		宝石数据1
	 * @param	gVo2		宝石数据2
	 * @return	是否相同
	 */
	private function checkSameGem(gVo1:GemVo, gVo2:GemVo):Boolean
	{
        if (!gVo1 || !gVo2) return false;
		return gVo1.row == gVo2.row && gVo1.column == gVo2.column;
	}
	
	/**
	 * 判断被选中的宝石数据是否属于上一次选中的周围4个。
	 * @param	gVo		被选中的另一个宝石数据
	 * @param	row		行坐标
	 * @param	column	列坐标
	 * @return	是否属于
	 */
	private function isRoundGem(gVo:GemVo, row:int, column:int):Boolean 
	{
		var arr:Array = this.getSelectRoundGem(row, column);
		var length:int = arr.length;
		for (var i:int = 0; i < length; i += 1)
		{
			if (this.checkSameGem(gVo, arr[i]))
				break;
		}
		if (i == length) return false;
		return true;
	}
	
	/**
	 * 交换位置效果
	 * @param	prevGVo	第一次选中的宝石数据
	 * @param	curGVo	第二次选中的宝石数据
	 * @param	yoyo	是否来回
	 */
	private function changePos(prevGVo:GemVo, curGVo:GemVo, yoyo:Boolean):void
	{
		var repeat:int = 0;
		if (yoyo) repeat = 1; 
        else this.changeVo(prevGVo, curGVo);
        prevGVo.isInPosition = false;
        curGVo.isInPosition = false;
		//交换位置
		TweenMax.to(prevGVo, .3, { x:curGVo.x, y:curGVo.y, 
									ease:Sine.easeOut, 
									repeat:repeat, yoyo:yoyo, onComplete:changeMotionComlpete, onCompleteParams:[prevGVo, curGVo] } );
		TweenMax.to(curGVo, .3, { x:prevGVo.x, y:prevGVo.y, 
									ease:Sine.easeOut, 
									repeat:repeat, yoyo:yoyo } );
	}
    
	/**
	 * 交换2个数据的行列
	 * @param	gVoA		宝石数据A
	 * @param	gVoB		宝石数据B
	 */
	private function changeVo(gVoA:GemVo, gVoB:GemVo):void 
	{
		//交换行列坐标
		var row:int = gVoA.row;
		var column:int = gVoA.column;
		this.gemList[gVoB.row][gVoB.column] = gVoA;
		this.gemList[row][column] = gVoB;
		gVoA.row = gVoB.row;
		gVoA.column = gVoB.column;
		gVoB.row = row;
		gVoB.column = column;
	}
	
    /**
     * 删除相同颜色的宝石
	 * 当交换动画结束后执行
     */
	private function removeSameColorGem():void 
	{
		if (!this.sameColorList || 
            this.sameColorList.length == 0) return;
		var gVo:GemVo;
		var length:int = this.sameColorList.length;
		//被删除数据的列坐标数组
		var columnList:Array = [];
		for (var i:int = length - 1; i >= 0; i -= 1) 
		{
			gVo = this.sameColorList[i];
			this.sameColorList.splice(i, 1);
			this.removeGem(gVo);
            //不存放相同的列数
            if (columnList.indexOf(gVo.column) == -1)
                columnList.push(gVo.column);
		}
		//填补被销毁的宝石
		this.reloadGem(columnList);
	}
    
    /**
     * 交换动画结束
     * @param	prevGVo	第一次选中的宝石数据
	 * @param	curGVo	第二次选中的宝石数据
     */
    private function changeMotionComlpete(prevGVo:GemVo, curGVo:GemVo):void 
    {
        prevGVo.isInPosition = true;
        curGVo.isInPosition = true;
        this.removeSameColorGem();
    }
	
	/**
	 * 填补被销毁的宝石
	 * @param	columnList		被删除的列坐标列表
	 */
	private function reloadGem(columnList:Array):void
	{
        if (!columnList) return;
        var length:int = columnList.length;
        //当前列坐标
        var column:int;
        var gVo:GemVo;
        //空行数量
        var nullNum:int = 0;
		var index:int;
		for (var i:int = 0; i < length; i += 1) 
        {
            column = columnList[i];
            nullNum = 0;
            for (var row:int = this.rows - 1; row >= 0; row -= 1) 
            {
                gVo = this.gemList[row][column];
                if (gVo) 
                {
                    //如果空行数量大于0 则往下移动空行数量个坐标
                    if (nullNum > 0)
                    {
                        gVo.isInPosition = false;
                        gVo.row += nullNum;
                        gVo.rangeY = this.getGemPos(row + nullNum, column).y;
                        this.gemList[row][column] = null;
                        this.gemList[row + nullNum][column] = gVo;
						index = this.fallList[column].indexOf(gVo);
						//trace("index", index);
						if (index == -1) this.fallList[column].push(gVo);
                    }
                }
                else nullNum++;
            }
            //填补空余的格子
            this.addColumn(nullNum, column);
			//根据行数降序排列
            this.fallList[column].sortOn("row", Array.NUMERIC | Array.DESCENDING);
        }
	}
    
    /**
     * 根据行数增加一列
     * @param	rowNum     被增加列的行数量
     * @param	column     增加的列坐标
     */
    private function addColumn(rowNum:int, column:int):void
    {
        if (rowNum <= 0) return;
        var gVo:GemVo;
        var point:Point;
		var columnList:Array;
        var color:int;
        for (var row:int = 0; row < rowNum; row += 1) 
        {
			columnList = this.fallList[column];
            gVo = new GemVo();
            gVo.row = row;
            gVo.column = column;
			gVo.g = 0;
			gVo.vy = 0;
            gVo.width = this.gemWidth;
            gVo.height = this.gemHeight;
			point = this.getGemPos(row, column);
			gVo.x = point.x;
            gVo.isInPosition = false;
            gVo.y = this.startY - (this.gemHeight + this.gapH) * 3;
            gVo.rangeY = point.y;
            //第一个颜色随机 
            if (row == 0) gVo.color = Random.randint(1, this.totalColorType);
            color = this.getUpVoColor(gVo.row, gVo.column);
            gVo.color = this.randomColor(color);
			columnList.push(gVo);
            this.gemList[row][column] = gVo;
			this.gemDict[gVo] = gVo;
            this.gemAddEvent.gVo = gVo;
            this.dispatchEvent(this.gemAddEvent);
        }
    }
	
	/**
	 * 判断2个宝石数据的颜色
	 * @param	gVo1	宝石数据1
	 * @param	gVo2	宝石数据2
	 * @return	2者交换位置并计算后颜色相同的宝石数据列表
	 */
	private function checkColor(gVo1:GemVo, gVo2:GemVo):Array
	{
		var sameColorList:Array = [];
		if (this.checkSameGem(gVo1, gVo2) || 
            !gVo1.isInPosition ||
            !gVo2.isInPosition ||
			gVo1.color == gVo2.color) return sameColorList;
		if (gVo1.column == gVo2.column)
			sameColorList = this.checkVColor(gVo1, gVo2); //判断横向颜色
		else if (gVo1.row == gVo2.row)
			sameColorList = this.checkHColor(gVo1, gVo2); //判断纵向颜色
		return sameColorList;
	}
	
	/**
	 * 判断纵向颜色
	 * @param	curGVo	第一次选中的宝石数据
	 * @param	gVo		第二次选中的宝石数据
	 * @return	待消除的列表
	 */
	private function checkVColor(curGVo:GemVo, gVo:GemVo):Array
	{
		//横向相同颜色的列表
		var sameVColorList:Array = [];
		//纵向相同颜色的列表
		var sameHColorList:Array = [];
		//临时横向列表
		var tempHArr:Array;
		//临时纵向列表
		var tempVArr:Array;
		//交换的2个数据
		var gVo1:GemVo;
		var gVo2:GemVo;
		//纵向交换
		if (curGVo.row < gVo.row)
		{
			//从上往下交换
			gVo1 = curGVo;
			gVo2 = gVo;
		}
		else
		{
			//从下往上交换
			gVo1 = gVo;
			gVo2 = curGVo;
		}
		//先判断上边
		//获取纵向相同的列表
		tempVArr = this.getUpSameColorVoList(gVo1.row, gVo1.column, gVo2.color);
		if (tempVArr.length >= this.minSameNum - 1) 
        {
            //保存起始节点
            tempVArr.unshift(gVo2);
			sameVColorList = sameVColorList.concat(tempVArr);
        }
			
		//判断左、右面
		//横向向相同的列表
		tempHArr = this.getLeftSameColorVoList(gVo1.row, gVo1.column, gVo2.color);
		tempHArr = tempHArr.concat(this.getRightSameColorVoList(gVo1.row, gVo1.column, gVo2.color));
		if (tempHArr.length >= this.minSameNum - 1) 
        {
            //如果纵向未保存过起始
            if (sameVColorList.indexOf(gVo2) == -1) tempHArr.unshift(gVo2);
			sameHColorList = sameHColorList.concat(tempHArr);
        }
		
		//先判断下边
		//获取纵向相同的列表
		tempVArr = this.getDownSameColorVoList(gVo2.row, gVo2.column, gVo1.color);
		if (tempVArr.length >= this.minSameNum - 1) 
        {
            //保存起始节点
            tempVArr.unshift(gVo1);
			sameVColorList = sameVColorList.concat(tempVArr);
        }
			
		//判断左、右面
		//横向向相同的列表
		tempHArr = this.getLeftSameColorVoList(gVo2.row, gVo2.column, gVo1.color);
		tempHArr = tempHArr.concat(this.getRightSameColorVoList(gVo2.row, gVo2.column, gVo1.color));
		if (tempHArr.length >= this.minSameNum - 1) 
        {
            //如果纵向未保存过起始
            if (sameHColorList.indexOf(gVo1) == -1) tempHArr.unshift(gVo1);
			sameHColorList = sameHColorList.concat(tempHArr);
        }
		return sameHColorList.concat(sameVColorList);
	}
	
	/**
	 * 判断横向颜色
	 * @param	curGVo	第一次选中的宝石数据
	 * @param	gVo		第二次选中的宝石数据
	 * @return	待消除的列表
	 */
	private function checkHColor(curGVo:GemVo, gVo:GemVo):Array
	{
		//横向相同颜色的列表
		var sameVColorList:Array = [];
		//纵向相同颜色的列表
		var sameHColorList:Array = [];
		//临时横向列表
		var tempHArr:Array;
		//临时纵向列表
		var tempVArr:Array;
		//交换的2个数据
		var gVo1:GemVo;
		var gVo2:GemVo;
		//横向交换
		if (curGVo.column < gVo.column)
		{
			//从左往右交换 
			gVo1 = curGVo;
			gVo2 = gVo;
		}
		else
		{
			//从右往左交换
			gVo1 = gVo;
			gVo2 = curGVo;
		}
		//先判断左边
		//获取横向相同的列表
		tempHArr = this.getLeftSameColorVoList(gVo1.row, gVo1.column, gVo2.color);
		//如果相同数量大于this.minSameNum则保持至sameHColorList
		if (tempHArr.length >= this.minSameNum - 1) 
        {
            //保存起始节点
            tempHArr.unshift(gVo2);
			sameHColorList = sameHColorList.concat(tempHArr);
        }
		
		//判断上、下面
		//纵向相同的列表
		tempVArr = this.getUpSameColorVoList(gVo1.row, gVo1.column, gVo2.color);
		tempVArr = tempVArr.concat(this.getDownSameColorVoList(gVo1.row, gVo1.column, gVo2.color));
		if (tempVArr.length >= this.minSameNum - 1) 
        {
            //如果纵向未保存过起始
            if (sameHColorList.indexOf(gVo2) == -1) tempVArr.unshift(gVo2);
			sameVColorList = sameVColorList.concat(tempVArr);
        }
		
		//再判断右边
		tempHArr = this.getRightSameColorVoList(gVo2.row, gVo2.column, gVo1.color);
		if (tempHArr.length >= this.minSameNum - 1) 
        {
            //保存起始节点
            tempHArr.unshift(gVo1);
			sameHColorList = sameHColorList.concat(tempHArr);
        }
		//判断上、下面
		//纵向相同的列表
		tempVArr = this.getUpSameColorVoList(gVo2.row, gVo2.column, gVo1.color);
		tempVArr = tempVArr.concat(this.getDownSameColorVoList(gVo2.row, gVo2.column, gVo1.color));
		if (tempVArr.length >= this.minSameNum - 1) 
        {
            //如果纵向未保存过起始
            if (sameHColorList.indexOf(gVo1) == -1) tempVArr.unshift(gVo1);
			sameVColorList = sameVColorList.concat(tempVArr);
        }
		return sameHColorList.concat(sameVColorList);
	}
    
    /**
     * 判断下落的宝石数据的颜色
     * @param	gVo     下落的宝石数据
     * @return  相同颜色数组
     */
    private function checkFallColor(gVo:GemVo):Array
    {
        //横向相同颜色的列表
		var sameVColorList:Array = [];
		//纵向相同颜色的列表
		var sameHColorList:Array = [];
        //已经在相同颜色列表中的不做判断
        if (!this.inSameColorList(gVo))
        {
            //临时横向列表
            var tempHArr:Array;
            //临时纵向列表
            var tempVArr:Array;
            //先判断下边
            //获取纵向相同的列表
            tempVArr = this.getDownSameColorVoList(gVo.row, gVo.column, gVo.color);
            tempVArr = tempVArr.concat(this.getUpSameColorVoList(gVo.row, gVo.column, gVo.color));
			if (tempVArr.length >= this.minSameNum - 1) 
            {
                //保存起始节点
                tempVArr.unshift(gVo);
                sameVColorList = sameVColorList.concat(tempVArr);
            }
                
            //判断左、右面
            //横向向相同的列表
            tempHArr = this.getLeftSameColorVoList(gVo.row, gVo.column, gVo.color);
            tempHArr = tempHArr.concat(this.getRightSameColorVoList(gVo.row, gVo.column, gVo.color));
			if (tempHArr.length >= this.minSameNum - 1)
            {
                //如果纵向未保存过起始
                if (sameHColorList.indexOf(gVo) == -1) tempHArr.unshift(gVo);
                sameHColorList = sameHColorList.concat(tempHArr);
            }
        }
        return sameHColorList.concat(sameVColorList);
    }
	
	/**
	 * 销毁宝石数据
	 * @param	gVo		宝石数据
	 */
	private function removeGem(gVo:GemVo):void
	{
		this.gemRemoveEvent.gVo = gVo;
		this.dispatchEvent(this.gemRemoveEvent);
		this.gemList[gVo.row][gVo.column] = null;
		delete this._gemDict[gVo];
	}
    
    /**
     * 是否处于待销毁的相同颜色列表中
     * @return      是否在待销毁列表中
     */
    private function inSameColorList(gVo:GemVo):Boolean
    {
		if (!gVo) return false;
        if (this.sameColorList && this.sameColorList.indexOf(gVo) != -1)
            return true;
        return false;
    }
    
    /**
     * 下落
     */
    private function fall():void
    {
        if (!this.fallList || this.fallList.length == 0) return;
        var length:int;
        var gVo:GemVo;
		for (var column:int = 0; column < this.columns; column += 1) 
        {
			for (var i:int = 0; i < this.fallList[column].length; i += 1)
			{
				gVo = this.fallList[column][i];
				gVo.vy += gVo.g;
				gVo.y += gVo.vy;
				if (i == 0)
				{
					gVo.g = this.g;
				}
				else
				{
					var prevGVo:GemVo = this.fallList[column][i - 1];
					if (Math.abs(prevGVo.y - gVo.y) >= this.fallGapV)
						gVo.g = this.g;
				}
				if (gVo.y >= gVo.rangeY)
				{
					gVo.y = gVo.rangeY;
                    gVo.isInPosition = true;
					gVo.vy = 0;
					gVo.g = 0;
					this.fallList[column].splice(i, 1);
                    this.sameColorList = this.sameColorList.concat(this.checkFallColor(gVo));
                    this.removeSameColorGem();
				}
			}
		}
    }
    
	//***********public function***********
	/**
	 * 点击宝石
	 * @param	posX	x位置	
	 * @param	posY	y位置
	 */
	public function selectGem(posX:Number, posY:Number):GemVo
	{
		if (!this.curGVo)
		{
			//没有宝石 则返回第一个点击的宝石
			this.curGVo = this.getGemVoByPos(posX, posY);
			if (!this.curGVo) return null;
            if (this.inSameColorList(this.curGVo) ||
				!this.curGVo.isInPosition)
            {
                this.curGVo = null;
                return this.curGVo;
            }
		}
		else
		{
			var gVo:GemVo = this.getGemVoByPos(posX, posY);
			if (!gVo) return null;
			//判断是否属于第一次点击的周围4个点
			if (!this.isRoundGem(gVo, this.curGVo.row, this.curGVo.column) || 
                !this.curGVo.isInPosition ||
                !gVo.isInPosition)
			{
				//不属于周围4个或者点击的2个点都在运动中
				this.curGVo = gVo;
				return this.curGVo;
			}
			//判断是否能交换
			this.sameColorList = this.checkColor(this.curGVo, gVo);
			if (this.sameColorList.length == 0) this.changePos(this.curGVo, gVo, true); //纵横没有相同颜色
			else this.changePos(this.curGVo, gVo, false); //有相同颜色
			this.curGVo = null;
		}
		return this.curGVo;
	}
	
	/**
	 * 判断是否有可交换的宝石数据
	 * @return		可交换的宝石数据
	 */
	public function checkCanChangeVo():GemVo
	{
		if (!this.gemList) return null;
		var gVo:GemVo;
		var leftGVo:GemVo;
		var downGVo:GemVo;
		for (var row:int = 0; row < this.rows; row += 1) 
		{
			for (var column:int = 0; column < this.columns; column += 1) 
			{
				gVo = this.gemList[row][column];
				if (column < this.columns - 1) leftGVo = this.gemList[row][column + 1];
				if (row < this.rows - 1) downGVo = this.gemList[row + 1][column];
				//判断交换左边和下边后sameList的数量是否大于0。
				if (leftGVo && this.checkColor(gVo, leftGVo).length > 0) 
				{
					this.curGVo = gVo;
					return gVo;
				}
				if (downGVo && this.checkColor(gVo, downGVo).length > 0) 
				{
					this.curGVo = gVo;
					return gVo;
				}
			}
			leftGVo = null;
			downGVo = null;
		}
		return null;
	}
    
    /**
     * 更新数据
     */
    public function update():void
    {
       this.fall();
    }
	
    /**
     * 销毁
     */
    public function destroy():void
    {
        this.gemList = null;
        this._gemDict = null;
		this.curGVo = null;
		this.colorList = null;
		this.sameColorList = null;
        this.gemRemoveEvent = null;
        this.gemAddEvent = null;
        this.fallList = null;
    }
	
	/**
     * 宝石字典
     */
	public function get gemDict():Dictionary{ return _gemDict; }
}
}
