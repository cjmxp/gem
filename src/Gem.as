package  
{
import com.greensock.easing.Sine;
import com.greensock.TweenMax;
import data.GemVo;
import events.GemEvent;
import flash.display.Stage;
import flash.events.EventDispatcher;
import flash.events.MouseEvent;
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
    //默认链接数量
    private var minLinkNum:uint;
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
    //舞台
    private var stage:Stage;
    //宝石宽度
    private var gemWidth:Number;
    //宝石高度
    private var gemHeight:Number;
    //起始位置x
    private var startX:Number;
    //起始位置y
    private var startY:Number;
    //总宽度
    private var totalWidth:Number;
    //总高度
    private var totalHeight:Number;
	//当前点击的宝石数据
	private var curGVo:GemVo;
	//宝石事件
	private var gemSelectEvent:GemEvent;
    /**
     * @param	totalColorType      总的颜色类型
     * @param	stage               舞台用于点击
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
    public function Gem(totalColorType:uint, stage:Stage, rows:uint, columns:uint, 
                        gapH:Number, gapV:Number, 
                        startX:Number, startY:Number, 
                        gemWidth:Number, gemHeight:Number,
                        minLinkNum:uint = 3) 
    {
        this.totalColorType = totalColorType;
        this.stage = stage;
        this.rows = rows;
        this.columns = columns;
        this.gemWidth = gemWidth;
        this.gemHeight = gemHeight;
        this.startX = startX;
        this.startY = startY;
        this.gapH = gapH;
        this.gapV = gapV;
        this.minLinkNum = minLinkNum;
        this.initData();
        this.initEvent();
    }
    
    /**
     * 初始化事件
     */
    private function initEvent():void 
    {
		this.gemSelectEvent = new GemEvent(GemEvent.SELECT);
        this.stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
    }
    
    private function mouseDownHandler(event:MouseEvent):void 
    {
        this.selectGem(event.stageX, event.stageY);
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
        this._gemDict = new Dictionary();
        var gVo:GemVo;
        var color:int;
        for (var row:int = 0; row < this.rows; row += 1) 
        {
            this.gemList[row] = [];
            for (var column:int = 0; column < this.columns; column += 1) 
            {
                gVo = new GemVo();
                gVo.x = this.startX + column * (this.gemWidth + this.gapH);
                gVo.y = this.startY + row * (this.gemHeight + this.gapV);
                gVo.width = this.gemWidth;
                gVo.height = this.gemHeight;
                gVo.row = row;
                gVo.column = column;
                this.gemList[row][column] = gVo;
                this._gemDict[gVo] = gVo;
                
                if (row < this.minLinkNum - 1 && 
					column < this.minLinkNum - 1)
                {
                    //第一行 第一列
                    //随机任意颜色
                    gVo.colorType = this.randomColor();
                }
                else
                {
					if (row < this.minLinkNum - 1 && 
						column >= this.minLinkNum - 1)
					{
						//前2行 后2列
						color = this.getLeftVoColor(row, column);
                        //如果左边相邻有2个以上的相同颜色则不使用此颜色
						if (color == 0) gVo.colorType = this.randomColor();
						else gVo.colorType = this.randomColor(color);
					}
					else if (column < this.minLinkNum - 1 && 
							row >= this.minLinkNum - 1)
					{
						//前2列 后2行
						color = this.getUpVoColor(row, column);
						if (color == 0) gVo.colorType = this.randomColor();
						else gVo.colorType = this.randomColor(color);
					}
					else
					{
						gVo.colorType = 0;
						//前2行 后2列
						var color1:int = this.getLeftVoColor(row, column);
						var color2:int = this.getUpVoColor(row, column);
						//根据前面相同颜色 生成不重复超过(this.minLinkNum - 1)次的颜色
						gVo.colorType = this.randomColor(color1, color2);
					}
                }
            }
        }
        this.totalWidth = this.rows * (this.gemWidth + this.gapH);
        this.totalHeight = this.columns * (this.gemHeight + this.gapV);
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
				color = prevGVo.colorType;
			}
			else
			{
				if (color == prevGVo.colorType) num++;
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
		if (curRow == 0) return 0;
		var color:int = 0;
		var prevGVo:GemVo;
		//相同颜色的数量
		var num:int = 0;
		for (var row:int = curRow - 1; row >= curRow - 2; row -= 1) 
        {
			prevGVo = this.gemList[row][curColumn];
			if (color == 0) 
			{
				color = prevGVo.colorType;
			}
			else
			{
				if (color == prevGVo.colorType) num++;
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
        if (curRow == 0) return null;
        var prevGVo:GemVo;
        var arr:Array = [];
        for (var column:int = curColumn - 1; column >= 0; column -= 1) 
        {
            prevGVo = this.gemList[curRow][column];
            if (prevGVo.colorType == color)
                arr.push(prevGVo);
            else 
                break;
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
		return gVo1.row == gVo2.row && gVo1.column == gVo2.column;
	}
	
	/**
	 * 判断被选中的宝石数据是否属于上一次选中的周围4个。
	 * @param	gVo		被选中的另一个宝石数据
	 * @param	row		行坐标
	 * @param	column	列坐标
	 * @return	是否属于
	 */
	private function checkRoundGem(gVo:GemVo, row:int, column:int):Boolean 
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
	 * 判断颜色
	 * @param	curGVo	第一次选中的宝石数据
	 * @param	gVo		第二次选中的宝石数据
	 */
	private function checkColor(curGVo:GemVo, gVo:GemVo):void
	{
		//颜色相同则不判断
		if (curGVo.colorType == gVo.colorType) 
		{
			//交换位置
			TweenMax.to(curGVo, .3, { x:gVo.x, y:gVo.y, 
										ease:Sine.easeOut, 
										repeat:1, yoyo:true } );
			TweenMax.to(gVo, .3, { x:curGVo.x, y:curGVo.y, 
										ease:Sine.easeOut, 
										repeat:1, yoyo:true } );
										
			
			this.curGVo = null;
			this.gemSelectEvent.gVo = null;
			this.dispatchEvent(this.gemSelectEvent);
			return;
		}
	}
	
	//***********public function***********
	/**
	 * 点击宝石
	 * @param	posX	x位置	
	 * @param	posY	y位置
	 */
	public function selectGem(posX:Number, posY:Number):void
	{
		if (!this.curGVo)
		{
			//没有宝石 则返回第一个点击的宝石
			this.curGVo = this.getGemVoByPos(posX, posY);
			this.gemSelectEvent.gVo = this.curGVo;
			this.dispatchEvent(this.gemSelectEvent);
		}
		else
		{
			var gVo:GemVo = this.getGemVoByPos(posX, posY);
			if (!gVo) return;
			//相同则取消点击
			if (this.checkSameGem(this.curGVo, gVo))
			{
				this.curGVo = null;
				this.gemSelectEvent.gVo = null;
				this.dispatchEvent(this.gemSelectEvent);
				return;
			}
			//判断是否属于第一次点击的周围4个点
			if (!this.checkRoundGem(gVo, this.curGVo.row, this.curGVo.column) || 
				TweenMax.isTweening(this.curGVo) || 
				TweenMax.isTweening(gVo))
			{
				//不属于周围4个或者点击的2个点都在运动中
				this.curGVo = gVo;
				this.gemSelectEvent.gVo = gVo;
				this.dispatchEvent(this.gemSelectEvent);
				return;
			}
			//判断颜色
			this.checkColor(this.curGVo, gVo);
		}
	}
	
    /**
     * 销毁
     */
    public function destroy():void
    {
        this.stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
        this.stage = null;
        this.gemList = null;
        this._gemDict = null;
		this.curGVo = null;
		this.colorList = null;
    }
	
	/**
     * 宝石字典
     */
	public function get gemDict():Dictionary{ return _gemDict; }
}
}