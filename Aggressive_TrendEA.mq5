//+------------------------------------------------------------------+
//|                           Advanced Trend EA v10.02              |
//|                     Cleaned Panel Layout - No Label Artifacts   |
//|                                  Copyright 2024, Your Company   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Company"
#property link      "https://www.mql5.com"
#property version   "10.02"
#property description "🚀 Professional Trend EA with Clean Dashboard"
#property description "✨ Features: Clean layout, no label artifacts"
#property description "📊 Press H key to toggle control panel"

#include <Trade\Trade.mqh>
CTrade trade;

//--- Trading direction enumeration
enum ENUM_TRADE_DIRECTION
{
    TRADE_BUY_ONLY = 0,     // Buy Only
    TRADE_SELL_ONLY = 1,    // Sell Only  
    TRADE_BOTH_SIDES = 2    // Both Directions
};

//--- Input parameters
input group "════════ TRADING SETTINGS ════════"
input double InitialLotSize = 0.1;                      // 💰 Initial Lot Size
input ENUM_TIMEFRAMES TradingTimeframe = PERIOD_M1;     // ⏰ Trading Timeframe (Used for Entry)
input double IndividualTradeTP = 2.0;                   // 🎯 Individual Trade TP (% of Account)
input long TPPipsBackup = 50;                           // 📏 Backup TP in Pips (forex only)
input double DrawdownLimit = 20.0;                      // ⚠️ Maximum Drawdown Limit (%)
input long MaxBuyTrades = 50;                           // 🔢 Maximum Number of Buy Trades
input long MaxSellTrades = 50;                          // 🔢 Maximum Number of Sell Trades

input group "════════ S/R SETTINGS ════════"
input bool EnableSRDetection = true;                    // 🎯 Enable Support/Resistance Detection
input int SRLookbackBars = 100;                        // 📊 Bars to Look Back for S/R
input double SRProximityPercent = 0.2;                 // 📏 S/R Proximity (% of price)
input bool ShowSRLines = true;                         // 📈 Show S/R Lines on Chart
input color ResistanceColor = clrRed;                  // 🔴 Resistance Line Color
input color SupportColor = clrGreen;                   // 🟢 Support Line Color

input group "════════ S/R TRADING BEHAVIOR ════════"
input bool PauseBuyNearResistance = false;             // ⏸️ Pause Buy trades near Resistance
input bool PauseSellNearSupport = false;               // ⏸️ Pause Sell trades near Support
input bool ReverseTradingAtSR = false;                 // 🔄 Enable Reverse Trading at S/R
input bool SellAtResistanceInBuyMode = false;          // 📉 Sell at Resistance (Buy mode only)
input bool BuyAtSupportInSellMode = false;             // 📈 Buy at Support (Sell mode only)

input group "════════ TRADING DIRECTION ════════"
input ENUM_TRADE_DIRECTION TradeDirection = TRADE_BOTH_SIDES;   // 🎯 Trading Direction

input group "════════ CRYPTO SETTINGS ════════"
input double CryptoMinMovement = 100.0;                 // 🪙 Minimum Crypto Price Movement
input double CryptoMaxMovement = 50000.0;               // 🪙 Maximum Crypto Price Movement

input group "════════ SESSION SETTINGS ════════"
input bool ShowSessionLines = true;                     // 📈 Show Session Lines
input color LondonSessionColor = clrBlue;               // 🇬🇧 London Session Color
input color NewYorkSessionColor = clrRed;               // 🇺🇸 New York Session Color

input group "════════ EA SETTINGS ════════"
input long MagicNumber = 777000;                        // 🔮 Magic Number
input bool EnableSounds = true;                         // 🔊 Enable Sound Alerts
input bool EnableDashboard = true;                      // 📊 Enable Dashboard Panel

//--- Global variables
datetime lastCandleTime = 0;
double dailyStartBalance = 0;
double currentLotSize = 0;
bool tradingPaused = false;
bool buyPausedNearResistance = false;
bool sellPausedNearSupport = false;
bool shouldSellAtResistance = false;
bool shouldBuyAtSupport = false;
ENUM_TIMEFRAMES WorkingTimeframe = PERIOD_M1;
bool isCryptoPair = false;
string symbolType = "";

//--- Support/Resistance levels (H4 and H1)
double currentH4Resistance = 0;
double currentH4Support = 0;
double currentH1Resistance = 0;
double currentH1Support = 0;
datetime lastSRCalculation = 0;


//--- Panel configuration (REDUCED HEIGHT)
bool panelVisible = true;
long panelX = 15;
long panelY = 35;
long panelWidth = 420;
input long panelHeight = 400;  // Reduced from 550 to 400

//--- Session times (GMT)
int LondonOpenHour = 8;    // 8:00 GMT
int LondonCloseHour = 16;  // 16:00 GMT
int NewYorkOpenHour = 13;  // 13:00 GMT (1:00 PM GMT)
int NewYorkCloseHour = 21; // 21:00 GMT (9:00 PM GMT)

//--- Function declarations
void CreateProfessionalPanel();
void UpdateRealTimeDashboard();
void CreateControlButtons();
void CreateSessionLines();
void TogglePanelVisibility();
void ShowPanel();
void HidePanel();
double CalculateTPAmount();
double CalculateTPMovement();
double CalculateTPPrice(bool isBuy, double openPrice);
string GetTradeDirectionString();
string GetTimeframeString();
long CountPositions();
long CountBuyPositions();
long CountSellPositions();
long CountProfitablePositions();
long CountLosingPositions();
double GetTotalProfit();
double GetCurrentDrawdown();
bool CloseAllTrades();
bool CloseAllProfitablePositions();
void CheckPercentageBasedTP();
void ExecuteAdvancedTradingLogic();
bool ValidateAllInputs();
void PlayAlertSound(string soundFile);
void UpdateSessionLines();
bool DetectSymbolType();
string GetSymbolTypeString();
void CalculateSupportResistance();
void DrawSRLines();
bool IsNearResistance(double price);
bool IsNearSupport(double price);
double NormalizeLotSize(double lotSize);
void CheckSRTradingConditions();
void CalculateTimeframeSR(ENUM_TIMEFRAMES timeframe, double &resistance, double &support, string tfName);

//+------------------------------------------------------------------+
//| Expert Advisor Initialization                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("════════════════════════════════════════════════════");
    Print("🚀 ADVANCED TREND EA v10.02 INITIALIZING...");
    Print("✨ Cleaned Panel Layout - No Label Artifacts");
    Print("════════════════════════════════════════════════════");
    
    // Detect symbol type first
    DetectSymbolType();
    
    // Initialize trading engine
    trade.SetExpertMagicNumber((ulong)MagicNumber);
    trade.SetDeviationInPoints(20);
    trade.SetTypeFilling(ORDER_FILLING_FOK);
    trade.LogLevel(LOG_LEVEL_ERRORS);
    
    // Setup core variables - USING INPUT TIMEFRAME
    WorkingTimeframe = TradingTimeframe;
    dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    currentLotSize = InitialLotSize;
    lastCandleTime = iTime(_Symbol, WorkingTimeframe, 0);
    
    // Validate all input parameters
    if(!ValidateAllInputs())
    {
        Print("❌ ERROR: Input validation failed!");
        PlayAlertSound("alert.wav");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    // Calculate initial S/R levels for both H4 and H1
    if(EnableSRDetection)
    {
        CalculateSupportResistance();
        if(ShowSRLines)
        {
            DrawSRLines();
        }
    }
    
    // Create professional interface
    if(EnableDashboard)
    {
        CreateProfessionalPanel();
        CreateControlButtons();
    }
    
    // Create session lines
    if(ShowSessionLines)
    {
        CreateSessionLines();
    }
    
    // Start update timer
    EventSetTimer(2); // Update every 2 seconds
    
    // Success notification
    Print("✅ EA INITIALIZATION COMPLETE");
    Print("📊 Symbol: ", _Symbol, " (", GetSymbolTypeString(), ")");
    Print("⏰ Working Timeframe: ", GetTimeframeString(), " (from input)");
    Print("💰 Lot Size: ", currentLotSize, " | Magic: ", (long)MagicNumber);
    Print("🎯 TP: ", IndividualTradeTP, "% = $", DoubleToString(CalculateTPAmount(), 2));
    Print("📈 Max Buy Trades: ", MaxBuyTrades);
    Print("📉 Max Sell Trades: ", MaxSellTrades);
    
    if(EnableSRDetection)
    {
        Print("📈 H4 Support: ", DoubleToString(currentH4Support, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
        Print("📉 H4 Resistance: ", DoubleToString(currentH4Resistance, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
        Print("📈 H1 Support: ", DoubleToString(currentH1Support, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
        Print("📉 H1 Resistance: ", DoubleToString(currentH1Resistance, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
        Print("⏸️ Pause Buy at Resistance: ", PauseBuyNearResistance ? "YES" : "NO");
        Print("⏸️ Pause Sell at Support: ", PauseSellNearSupport ? "YES" : "NO");
        Print("🔄 Reverse Trading: ", ReverseTradingAtSR ? "YES" : "NO");
    }
    
    Print("⌨️ Press H key to toggle control panel");
    Print("════════════════════════════════════════════════════");
    
    // Only play sound on initial load, not on timeframe changes
    static bool firstInit = true;
    if(firstInit)
    {
        PlayAlertSound("news.wav");
        firstInit = false;
    }
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Calculate Support and Resistance Levels from H4 and H1         |
//+------------------------------------------------------------------+
void CalculateSupportResistance()
{
    if(!EnableSRDetection) return;
    
    // Calculate H4 S/R levels
    CalculateTimeframeSR(PERIOD_H4, currentH4Resistance, currentH4Support, "H4");
    
    // Calculate H1 S/R levels (informational)
    CalculateTimeframeSR(PERIOD_H1, currentH1Resistance, currentH1Support, "H1");
    
    lastSRCalculation = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Calculate S/R for specific timeframe                            |
//+------------------------------------------------------------------+
void CalculateTimeframeSR(ENUM_TIMEFRAMES timeframe, double &resistance, double &support, string tfName)
{
    int bars = iBars(_Symbol, timeframe);
    if(bars < SRLookbackBars)
    {
        Print("⚠️ Not enough ", tfName, " bars for S/R calculation");
        return;
    }
    
    double highs[], lows[];
    ArrayResize(highs, SRLookbackBars);
    ArrayResize(lows, SRLookbackBars);
    
    // Copy price data for the specified timeframe
    if(CopyHigh(_Symbol, timeframe, 0, SRLookbackBars, highs) <= 0 ||
       CopyLow(_Symbol, timeframe, 0, SRLookbackBars, lows) <= 0)
    {
        Print("❌ Failed to copy ", tfName, " price data for S/R");
        return;
    }
    
    // Find highest high (resistance) and lowest low (support)
    double highestHigh = highs[ArrayMaximum(highs)];
    double lowestLow = lows[ArrayMinimum(lows)];
    
    // Find significant levels using a more sophisticated approach
    double significantResistance = 0;
    double significantSupport = DBL_MAX;
    
    // Count touches for each level
    for(int i = 10; i < SRLookbackBars - 10; i++)
    {
        double high = highs[i];
        double low = lows[i];
        
        // Check if this high is a local peak
        bool isPeak = true;
        for(int j = i-3; j <= i+3; j++)
        {
            if(j != i && j >= 0 && j < SRLookbackBars)
            {
                if(highs[j] > high)
                {
                    isPeak = false;
                    break;
                }
            }
        }
        
        if(isPeak && high > significantResistance && high < highestHigh)
        {
            significantResistance = high;
        }
        
        // Check if this low is a local trough
        bool isTrough = true;
        for(int j = i-3; j <= i+3; j++)
        {
            if(j != i && j >= 0 && j < SRLookbackBars)
            {
                if(lows[j] < low)
                {
                    isTrough = false;
                    break;
                }
            }
        }
        
        if(isTrough && low < significantSupport && low > lowestLow)
        {
            significantSupport = low;
        }
    }
    
    // Update S/R levels
    if(significantResistance > 0)
        resistance = significantResistance;
    else
        resistance = highestHigh;
        
    if(significantSupport < DBL_MAX)
        support = significantSupport;
    else
        support = lowestLow;
    
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    Print("📊 ", tfName, " S/R Updated - Support: ", DoubleToString(support, digits), 
          " | Resistance: ", DoubleToString(resistance, digits));
}

//+------------------------------------------------------------------+
//| Check S/R Trading Conditions (uses H4 levels for trading)      |
//+------------------------------------------------------------------+
void CheckSRTradingConditions()
{
    if(!EnableSRDetection) return;
    
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // Reset conditions
    buyPausedNearResistance = false;
    sellPausedNearSupport = false;
    shouldSellAtResistance = false;
    shouldBuyAtSupport = false;
    
    // Check pause conditions (if enabled) - Use H4 levels for trading decisions
    if(PauseBuyNearResistance && IsNearResistance(currentPrice))
    {
        buyPausedNearResistance = true;
    }
    
    if(PauseSellNearSupport && IsNearSupport(currentPrice))
    {
        sellPausedNearSupport = true;
    }
    
    // Check reverse trading conditions (if enabled)
    if(ReverseTradingAtSR)
    {
        // In Buy mode, check if we should sell at resistance
        if(TradeDirection == TRADE_BUY_ONLY && SellAtResistanceInBuyMode && IsNearResistance(currentPrice))
        {
            shouldSellAtResistance = true;
        }
        
        // In Sell mode, check if we should buy at support
        if(TradeDirection == TRADE_SELL_ONLY && BuyAtSupportInSellMode && IsNearSupport(currentPrice))
        {
            shouldBuyAtSupport = true;
        }
    }
    
    // Log status changes
    static bool lastBuyPaused = false;
    static bool lastSellPaused = false;
    static bool lastShouldSell = false;
    static bool lastShouldBuy = false;
    
    if(buyPausedNearResistance != lastBuyPaused)
    {
        if(buyPausedNearResistance)
            Print("⚠️ BUY trades PAUSED - Near H4 Resistance");
        else
            Print("✅ BUY trades RESUMED - Away from H4 Resistance");
        lastBuyPaused = buyPausedNearResistance;
    }
    
    if(sellPausedNearSupport != lastSellPaused)
    {
        if(sellPausedNearSupport)
            Print("⚠️ SELL trades PAUSED - Near H4 Support");
        else
            Print("✅ SELL trades RESUMED - Away from H4 Support");
        lastSellPaused = sellPausedNearSupport;
    }
    
    if(shouldSellAtResistance != lastShouldSell)
    {
        if(shouldSellAtResistance)
            Print("🔄 REVERSE TRADING: Selling at Resistance (Buy mode)");
        lastShouldSell = shouldSellAtResistance;
    }
    
    if(shouldBuyAtSupport != lastShouldBuy)
    {
        if(shouldBuyAtSupport)
            Print("🔄 REVERSE TRADING: Buying at Support (Sell mode)");
        lastShouldBuy = shouldBuyAtSupport;
    }
}

//+------------------------------------------------------------------+
//| Draw Support and Resistance Lines on Chart (H4 and H1)         |
//+------------------------------------------------------------------+
void DrawSRLines()
{
    if(!ShowSRLines || !EnableSRDetection) return;
    
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    // Draw H4 Resistance Line
    string h4ResName = "H4_Resistance_Line";
    ObjectDelete(0, h4ResName);
    if(ObjectCreate(0, h4ResName, OBJ_HLINE, 0, 0, currentH4Resistance))
    {
        ObjectSetInteger(0, h4ResName, OBJPROP_COLOR, ResistanceColor);
        ObjectSetInteger(0, h4ResName, OBJPROP_WIDTH, 3);  // Thicker for H4
        ObjectSetInteger(0, h4ResName, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, h4ResName, OBJPROP_BACK, false);
        ObjectSetString(0, h4ResName, OBJPROP_TEXT, "H4 Resistance: " + DoubleToString(currentH4Resistance, digits));
    }
    
    // Draw H4 Support Line
    string h4SupName = "H4_Support_Line";
    ObjectDelete(0, h4SupName);
    if(ObjectCreate(0, h4SupName, OBJ_HLINE, 0, 0, currentH4Support))
    {
        ObjectSetInteger(0, h4SupName, OBJPROP_COLOR, SupportColor);
        ObjectSetInteger(0, h4SupName, OBJPROP_WIDTH, 3);  // Thicker for H4
        ObjectSetInteger(0, h4SupName, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, h4SupName, OBJPROP_BACK, false);
        ObjectSetString(0, h4SupName, OBJPROP_TEXT, "H4 Support: " + DoubleToString(currentH4Support, digits));
    }
    
    // Draw H1 Resistance Line (informational)
    string h1ResName = "H1_Resistance_Line";
    ObjectDelete(0, h1ResName);
    if(ObjectCreate(0, h1ResName, OBJ_HLINE, 0, 0, currentH1Resistance))
    {
        ObjectSetInteger(0, h1ResName, OBJPROP_COLOR, ResistanceColor);
        ObjectSetInteger(0, h1ResName, OBJPROP_WIDTH, 1);  // Thinner for H1
        ObjectSetInteger(0, h1ResName, OBJPROP_STYLE, STYLE_DASH);
        ObjectSetInteger(0, h1ResName, OBJPROP_BACK, false);
        ObjectSetString(0, h1ResName, OBJPROP_TEXT, "H1 Resistance: " + DoubleToString(currentH1Resistance, digits));
    }
    
    // Draw H1 Support Line (informational)
    string h1SupName = "H1_Support_Line";
    ObjectDelete(0, h1SupName);
    if(ObjectCreate(0, h1SupName, OBJ_HLINE, 0, 0, currentH1Support))
    {
        ObjectSetInteger(0, h1SupName, OBJPROP_COLOR, SupportColor);
        ObjectSetInteger(0, h1SupName, OBJPROP_WIDTH, 1);  // Thinner for H1
        ObjectSetInteger(0, h1SupName, OBJPROP_STYLE, STYLE_DASH);
        ObjectSetInteger(0, h1SupName, OBJPROP_BACK, false);
        ObjectSetString(0, h1SupName, OBJPROP_TEXT, "H1 Support: " + DoubleToString(currentH1Support, digits));
    }
    
    // Draw labels
    string h4ResLabel = "H4_Resistance_Label";
    ObjectDelete(0, h4ResLabel);
    if(ObjectCreate(0, h4ResLabel, OBJ_TEXT, 0, TimeCurrent(), currentH4Resistance))
    {
        ObjectSetString(0, h4ResLabel, OBJPROP_TEXT, " ← H4 RESISTANCE");
        ObjectSetInteger(0, h4ResLabel, OBJPROP_COLOR, ResistanceColor);
        ObjectSetInteger(0, h4ResLabel, OBJPROP_FONTSIZE, 10);
        ObjectSetString(0, h4ResLabel, OBJPROP_FONT, "Arial Bold");
        ObjectSetInteger(0, h4ResLabel, OBJPROP_ANCHOR, ANCHOR_LEFT);
    }
    
    string h4SupLabel = "H4_Support_Label";
    ObjectDelete(0, h4SupLabel);
    if(ObjectCreate(0, h4SupLabel, OBJ_TEXT, 0, TimeCurrent(), currentH4Support))
    {
        ObjectSetString(0, h4SupLabel, OBJPROP_TEXT, " ← H4 SUPPORT");
        ObjectSetInteger(0, h4SupLabel, OBJPROP_COLOR, SupportColor);
        ObjectSetInteger(0, h4SupLabel, OBJPROP_FONTSIZE, 10);
        ObjectSetString(0, h4SupLabel, OBJPROP_FONT, "Arial Bold");
        ObjectSetInteger(0, h4SupLabel, OBJPROP_ANCHOR, ANCHOR_LEFT);
    }
    
    string h1ResLabel = "H1_Resistance_Label";
    ObjectDelete(0, h1ResLabel);
    if(ObjectCreate(0, h1ResLabel, OBJ_TEXT, 0, TimeCurrent(), currentH1Resistance))
    {
        ObjectSetString(0, h1ResLabel, OBJPROP_TEXT, " ← H1 RES");
        ObjectSetInteger(0, h1ResLabel, OBJPROP_COLOR, ResistanceColor);
        ObjectSetInteger(0, h1ResLabel, OBJPROP_FONTSIZE, 8);
        ObjectSetString(0, h1ResLabel, OBJPROP_FONT, "Arial");
        ObjectSetInteger(0, h1ResLabel, OBJPROP_ANCHOR, ANCHOR_LEFT);
    }
    
    string h1SupLabel = "H1_Support_Label";
    ObjectDelete(0, h1SupLabel);
    if(ObjectCreate(0, h1SupLabel, OBJ_TEXT, 0, TimeCurrent(), currentH1Support))
    {
        ObjectSetString(0, h1SupLabel, OBJPROP_TEXT, " ← H1 SUP");
        ObjectSetInteger(0, h1SupLabel, OBJPROP_COLOR, SupportColor);
        ObjectSetInteger(0, h1SupLabel, OBJPROP_FONTSIZE, 8);
        ObjectSetString(0, h1SupLabel, OBJPROP_FONT, "Arial");
        ObjectSetInteger(0, h1SupLabel, OBJPROP_ANCHOR, ANCHOR_LEFT);
    }
    
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Check if Price is Near Resistance (uses H4 levels)             |
//+------------------------------------------------------------------+
bool IsNearResistance(double price)
{
    if(!EnableSRDetection || currentH4Resistance <= 0) return false;
    
    double proximity = currentH4Resistance * (SRProximityPercent / 100.0);
    return (price >= currentH4Resistance - proximity && price <= currentH4Resistance + proximity);
}

//+------------------------------------------------------------------+
//| Check if Price is Near Support (uses H4 levels)                |
//+------------------------------------------------------------------+
bool IsNearSupport(double price)
{
    if(!EnableSRDetection || currentH4Support <= 0) return false;
    
    double proximity = currentH4Support * (SRProximityPercent / 100.0);
    return (price >= currentH4Support - proximity && price <= currentH4Support + proximity);
}

//+------------------------------------------------------------------+
//| Expert Advisor Deinitialization                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("🔄 Advanced Trend EA v10.02 shutting down...");
    
    // Stop timer
    EventKillTimer();
    
    // Clean up all interface objects
    string objectsToDelete[30];
    objectsToDelete[0] = "EA_Panel_Background";
    objectsToDelete[1] = "EA_Panel_Header";
    objectsToDelete[2] = "EA_Panel_Title";
    objectsToDelete[3] = "EA_Toggle_Hint";
    objectsToDelete[4] = "Btn_CloseProfits";
    objectsToDelete[5] = "Btn_CloseAll";
    objectsToDelete[6] = "Btn_PauseResume";
    objectsToDelete[7] = "LondonSession_Line";
    objectsToDelete[8] = "NewYorkSession_Line";
    objectsToDelete[9] = "LondonSession_Label";
    objectsToDelete[10] = "NewYorkSession_Label";
    objectsToDelete[11] = "H4_Resistance_Line";
    objectsToDelete[12] = "H4_Support_Line";
    objectsToDelete[13] = "H4_Resistance_Label";
    objectsToDelete[14] = "H4_Support_Label";
    objectsToDelete[15] = "H1_Resistance_Line";
    objectsToDelete[16] = "H1_Support_Line";
    objectsToDelete[17] = "H1_Resistance_Label";
    objectsToDelete[18] = "H1_Support_Label";
    objectsToDelete[19] = "Dashboard_Balance_Value";
    objectsToDelete[20] = "Dashboard_Equity_Value";
    objectsToDelete[21] = "Dashboard_Buy_Count";
    objectsToDelete[22] = "Dashboard_Sell_Count";
    objectsToDelete[23] = "Dashboard_DailyPL";
    objectsToDelete[24] = "Dashboard_TotalPos";
    objectsToDelete[25] = "Dashboard_ProfitSummary";
    objectsToDelete[26] = "Dashboard_NetPL";
    objectsToDelete[27] = "Dashboard_TP";
    objectsToDelete[28] = "Dashboard_Symbol";
    objectsToDelete[29] = "Dashboard_H4Res";
    
    for(int i = 0; i < 30; i++)
    {
        ObjectDelete(0, objectsToDelete[i]);
    }
    
    // Clean up additional dashboard elements
    ObjectDelete(0, "Dashboard_H4Sup");
    ObjectDelete(0, "Dashboard_H1Res");
    ObjectDelete(0, "Dashboard_H1Sup");
    ObjectDelete(0, "Dashboard_SRBehavior");
    ObjectDelete(0, "Dashboard_Reverse");
    ObjectDelete(0, "Dashboard_BuyStatus");
    ObjectDelete(0, "Dashboard_SellStatus");
    
    // Clean up any remaining dashboard elements
    for(int i = 0; i < 50; i++)
    {
        ObjectDelete(0, "Dashboard_" + IntegerToString(i));
    }
    
    ChartRedraw(0);
    Print("✅ Advanced Trend EA v10.02 deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Main Trading Logic - OnTick                                     |
//+------------------------------------------------------------------+
void OnTick()
{
    // Basic trading permission checks
    if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || 
       !AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) ||
       !SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE))
        return;
    
    // Skip if trading is globally paused
    if(tradingPaused) return;
    
    // Update S/R levels every 30 minutes
    if(EnableSRDetection && TimeCurrent() - lastSRCalculation > 1800)
    {
        CalculateSupportResistance();
        if(ShowSRLines)
        {
            DrawSRLines();
        }
    }
    
    // Check S/R trading conditions
    CheckSRTradingConditions();
    
    // New candle detection using INPUT TIMEFRAME
    datetime currentCandle = iTime(_Symbol, WorkingTimeframe, 0);
    if(currentCandle != lastCandleTime && currentCandle > 0)
    {
        lastCandleTime = currentCandle;
        
        // Get current position counts
        long buyPositions = CountBuyPositions();
        long sellPositions = CountSellPositions();
        
        // Check if we can open new trades based on direction-specific limits
        bool canOpenBuy = false;
        bool canOpenSell = false;
        
        if(TradeDirection == TRADE_BUY_ONLY || TradeDirection == TRADE_BOTH_SIDES)
        {
            canOpenBuy = (buyPositions < MaxBuyTrades);
        }
        
        if(TradeDirection == TRADE_SELL_ONLY || TradeDirection == TRADE_BOTH_SIDES)
        {
            canOpenSell = (sellPositions < MaxSellTrades);
        }
        
        // Execute trades if allowed
        if(canOpenBuy || canOpenSell)
        {
            ExecuteAdvancedTradingLogic();
        }
        else
        {
            static datetime lastWarning = 0;
            if(TimeCurrent() - lastWarning > 300) // Warn every 5 minutes
            {
                if(!canOpenBuy && (TradeDirection == TRADE_BUY_ONLY || TradeDirection == TRADE_BOTH_SIDES))
                    Print("⚠️ Maximum BUY trades limit reached: ", (long)MaxBuyTrades);
                if(!canOpenSell && (TradeDirection == TRADE_SELL_ONLY || TradeDirection == TRADE_BOTH_SIDES))
                    Print("⚠️ Maximum SELL trades limit reached: ", (long)MaxSellTrades);
                lastWarning = TimeCurrent();
            }
        }
    }
    
    // Monitor percentage-based take profits
    CheckPercentageBasedTP();
    
    // Update session lines
    if(ShowSessionLines)
    {
        UpdateSessionLines();
    }
    
    // Automatic drawdown protection
    double currentDD = GetCurrentDrawdown();
    if(currentDD >= DrawdownLimit)
    {
        if(!tradingPaused)
        {
            tradingPaused = true;
            Print("🚨 DRAWDOWN LIMIT REACHED: ", DoubleToString(currentDD, 2), "%");
            Print("⏸️ Trading automatically paused for protection!");
            PlayAlertSound("alert.wav");
            UpdateRealTimeDashboard();
        }
    }
}

//+------------------------------------------------------------------+
//| Advanced Trading Logic Execution                                |
//+------------------------------------------------------------------+
void ExecuteAdvancedTradingLogic()
{
    // Get current market prices
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double spread = ask - bid;
    
    if(ask <= 0 || bid <= 0) 
    {
        Print("❌ Invalid prices - Ask: ", ask, " Bid: ", bid);
        return;
    }
    
    // Get current position counts
    long buyPositions = CountBuyPositions();
    long sellPositions = CountSellPositions();
    
    // Prepare trade parameters
    double lotSize = NormalizeLotSize(currentLotSize);
    double tpAmountUSD = CalculateTPAmount();
    double tpMovement = CalculateTPMovement();
    
    // Get symbol digits for proper formatting
    long symbolDigits = SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    Print("📊 New ", GetTimeframeString(), " candle on ", GetSymbolTypeString());
    Print("💰 Spread: ", DoubleToString(spread, (int)symbolDigits));
    
    // Determine if we should execute normal or reverse trades
    bool executeBuy = false;
    bool executeSell = false;
    
    // Normal trading logic with position limit checks
    if(TradeDirection == TRADE_BUY_ONLY || TradeDirection == TRADE_BOTH_SIDES)
    {
        if(!buyPausedNearResistance && buyPositions < MaxBuyTrades)
            executeBuy = true;
    }
    
    if(TradeDirection == TRADE_SELL_ONLY || TradeDirection == TRADE_BOTH_SIDES)
    {
        if(!sellPausedNearSupport && sellPositions < MaxSellTrades)
            executeSell = true;
    }
    
    // Reverse trading logic (overrides normal if conditions met)
    if(shouldSellAtResistance && sellPositions < MaxSellTrades)
    {
        executeBuy = false;  // Cancel normal buy
        executeSell = true;   // Force sell
        Print("🔄 Executing REVERSE SELL at Resistance");
    }
    
    if(shouldBuyAtSupport && buyPositions < MaxBuyTrades)
    {
        executeSell = false;  // Cancel normal sell
        executeBuy = true;    // Force buy
        Print("🔄 Executing REVERSE BUY at Support");
    }
    
    // Execute BUY trades
    if(executeBuy)
    {
        double buyTP = CalculateTPPrice(true, ask);
        
        // Validate TP is correct for BUY
        if(buyTP <= ask)
        {
            Print("⚠️ BUY TP calculation error - using backup");
            if(isCryptoPair)
                buyTP = ask + CryptoMinMovement;
            else
                buyTP = ask + ((double)TPPipsBackup * SymbolInfoDouble(_Symbol, SYMBOL_POINT) * (symbolDigits == 5 ? 10 : 1));
        }
        
        if(trade.Buy(lotSize, _Symbol, ask, 0, buyTP, "ADV_TRENDEA"))
        {
            Print("✅ BUY SUCCESS: Ticket #", trade.ResultOrder());
            Print("   📈 Entry: ", DoubleToString(ask, (int)symbolDigits));
            Print("   🎯 TP: ", DoubleToString(buyTP, (int)symbolDigits));
            Print("   📊 Buy Positions: ", buyPositions + 1, "/", MaxBuyTrades);
            
            if(isCryptoPair)
            {
                Print("   🪙 Movement: +", DoubleToString(buyTP - ask, (int)symbolDigits), " points = $", DoubleToString(tpAmountUSD, 2));
            }
            else
            {
                Print("   📈 Movement: +", DoubleToString(tpMovement, 1), " pips = $", DoubleToString(tpAmountUSD, 2));
            }
            
            PlayAlertSound("ok.wav");
        }
        else
        {
            Print("❌ BUY FAILED: ", trade.ResultRetcodeDescription());
        }
    }
    else if(buyPausedNearResistance && (TradeDirection == TRADE_BUY_ONLY || TradeDirection == TRADE_BOTH_SIDES))
    {
        Print("⏸️ BUY trade skipped - Near H4 Resistance");
    }
    else if(buyPositions >= MaxBuyTrades && (TradeDirection == TRADE_BUY_ONLY || TradeDirection == TRADE_BOTH_SIDES))
    {
        Print("⚠️ BUY trade skipped - Max buy limit reached");
    }
    
    // Execute SELL trades
    if(executeSell)
    {
        double sellTP = CalculateTPPrice(false, bid);
        
        // Validate TP is correct for SELL
        if(sellTP >= bid)
        {
            Print("⚠️ SELL TP calculation error - using backup");
            if(isCryptoPair)
                sellTP = bid - CryptoMinMovement;
            else
                sellTP = bid - ((double)TPPipsBackup * SymbolInfoDouble(_Symbol, SYMBOL_POINT) * (symbolDigits == 5 ? 10 : 1));
        }
        
        if(trade.Sell(lotSize, _Symbol, bid, 0, sellTP, "ADV_TRENDEA"))
        {
            Print("✅ SELL SUCCESS: Ticket #", trade.ResultOrder());
            Print("   📉 Entry: ", DoubleToString(bid, (int)symbolDigits));
            Print("   🎯 TP: ", DoubleToString(sellTP, (int)symbolDigits));
            Print("   📊 Sell Positions: ", sellPositions + 1, "/", MaxSellTrades);
            
            if(isCryptoPair)
            {
                Print("   🪙 Movement: -", DoubleToString(bid - sellTP, (int)symbolDigits), " points = $", DoubleToString(tpAmountUSD, 2));
            }
            else
            {
                Print("   📈 Movement: -", DoubleToString(tpMovement, 1), " pips = $", DoubleToString(tpAmountUSD, 2));
            }
            
            PlayAlertSound("ok.wav");
        }
        else
        {
            Print("❌ SELL FAILED: ", trade.ResultRetcodeDescription());
        }
    }
    else if(sellPausedNearSupport && (TradeDirection == TRADE_SELL_ONLY || TradeDirection == TRADE_BOTH_SIDES))
    {
        Print("⏸️ SELL trade skipped - Near H4 Support");
    }
    else if(sellPositions >= MaxSellTrades && (TradeDirection == TRADE_SELL_ONLY || TradeDirection == TRADE_BOTH_SIDES))
    {
        Print("⚠️ SELL trade skipped - Max sell limit reached");
    }
}

//+------------------------------------------------------------------+
//| Chart Event Handler with H Key Toggle                           |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    // Handle keyboard events for panel toggle
    if(id == CHARTEVENT_KEYDOWN)
    {
        if(lparam == 72 || lparam == 104) // H or h key
        {
            TogglePanelVisibility();
            Print("🎛️ Panel toggled with H key - Visible: ", panelVisible ? "Yes" : "No");
            PlayAlertSound("tick.wav");
        }
    }
    
    // Handle control button clicks
    if(id == CHARTEVENT_OBJECT_CLICK)
    {
        if(sparam == "Btn_CloseProfits")
        {
            bool success = CloseAllProfitablePositions();
            ObjectSetInteger(0, "Btn_CloseProfits", OBJPROP_STATE, false);
            Print("💰 Close Profitable Positions clicked - Success: ", success ? "Yes" : "No");
        }
        else if(sparam == "Btn_CloseAll")
        {
            bool success = CloseAllTrades();
            ObjectSetInteger(0, "Btn_CloseAll", OBJPROP_STATE, false);
            Print("🚨 Close All Positions clicked - Success: ", success ? "Yes" : "No");
        }
        else if(sparam == "Btn_PauseResume")
        {
            tradingPaused = !tradingPaused;
            
            string btnText = tradingPaused ? "Resume" : "Pause";
            color btnColor = tradingPaused ? clrBlue : clrOrange;
            
            ObjectSetString(0, "Btn_PauseResume", OBJPROP_TEXT, btnText);
            ObjectSetInteger(0, "Btn_PauseResume", OBJPROP_BGCOLOR, btnColor);
            ObjectSetInteger(0, "Btn_PauseResume", OBJPROP_STATE, false);
            
            Print("🎮 Trading ", tradingPaused ? "PAUSED" : "RESUMED");
            PlayAlertSound(tradingPaused ? "alert.wav" : "ok.wav");
            UpdateRealTimeDashboard();
        }
        
        ChartRedraw(0);
    }
}

//+------------------------------------------------------------------+
//| Timer Function for Real-time Updates                            |
//+------------------------------------------------------------------+
void OnTimer()
{
    if(EnableDashboard && panelVisible)
    {
        UpdateRealTimeDashboard();
    }
    
    if(ShowSessionLines)
    {
        UpdateSessionLines();
    }
    
    // Update S/R lines position periodically
    if(ShowSRLines && EnableSRDetection)
    {
        // Update label positions to current time
        ObjectSetInteger(0, "H4_Resistance_Label", OBJPROP_TIME, TimeCurrent());
        ObjectSetInteger(0, "H4_Support_Label", OBJPROP_TIME, TimeCurrent());
        ObjectSetInteger(0, "H1_Resistance_Label", OBJPROP_TIME, TimeCurrent());
        ObjectSetInteger(0, "H1_Support_Label", OBJPROP_TIME, TimeCurrent());
    }
}

//+------------------------------------------------------------------+
//| Create Professional Panel Interface                             |
//+------------------------------------------------------------------+
void CreateProfessionalPanel()
{
    // Main panel background
    ObjectDelete(0, "EA_Panel_Background");
    if(ObjectCreate(0, "EA_Panel_Background", OBJ_RECTANGLE_LABEL, 0, 0, 0))
    {
        ObjectSetInteger(0, "EA_Panel_Background", OBJPROP_XDISTANCE, panelX);
        ObjectSetInteger(0, "EA_Panel_Background", OBJPROP_YDISTANCE, panelY);
        ObjectSetInteger(0, "EA_Panel_Background", OBJPROP_XSIZE, panelWidth);
        ObjectSetInteger(0, "EA_Panel_Background", OBJPROP_YSIZE, panelHeight);
        ObjectSetInteger(0, "EA_Panel_Background", OBJPROP_BGCOLOR, C'20,20,25');
        ObjectSetInteger(0, "EA_Panel_Background", OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(0, "EA_Panel_Background", OBJPROP_COLOR, C'100,100,120');
        ObjectSetInteger(0, "EA_Panel_Background", OBJPROP_WIDTH, 2);
        ObjectSetInteger(0, "EA_Panel_Background", OBJPROP_BACK, false);
        ObjectSetInteger(0, "EA_Panel_Background", OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, "EA_Panel_Background", OBJPROP_HIDDEN, true);
    }
    
    // Header background
    ObjectDelete(0, "EA_Panel_Header");
    if(ObjectCreate(0, "EA_Panel_Header", OBJ_RECTANGLE_LABEL, 0, 0, 0))
    {
        ObjectSetInteger(0, "EA_Panel_Header", OBJPROP_XDISTANCE, panelX);
        ObjectSetInteger(0, "EA_Panel_Header", OBJPROP_YDISTANCE, panelY);
        ObjectSetInteger(0, "EA_Panel_Header", OBJPROP_XSIZE, panelWidth);
        ObjectSetInteger(0, "EA_Panel_Header", OBJPROP_YSIZE, 32);
        ObjectSetInteger(0, "EA_Panel_Header", OBJPROP_BGCOLOR, C'0,60,120');
        ObjectSetInteger(0, "EA_Panel_Header", OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(0, "EA_Panel_Header", OBJPROP_COLOR, C'0,80,160');
        ObjectSetInteger(0, "EA_Panel_Header", OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, "EA_Panel_Header", OBJPROP_BACK, false);
        ObjectSetInteger(0, "EA_Panel_Header", OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, "EA_Panel_Header", OBJPROP_HIDDEN, true);
    }
    
    // Panel title
    ObjectDelete(0, "EA_Panel_Title");
    if(ObjectCreate(0, "EA_Panel_Title", OBJ_LABEL, 0, 0, 0))
    {
        ObjectSetInteger(0, "EA_Panel_Title", OBJPROP_XDISTANCE, panelX + 12);
        ObjectSetInteger(0, "EA_Panel_Title", OBJPROP_YDISTANCE, panelY + 7);
        ObjectSetString(0, "EA_Panel_Title", OBJPROP_TEXT, "🚀 ADVANCED TREND EA v10.02");
        ObjectSetInteger(0, "EA_Panel_Title", OBJPROP_COLOR, clrWhite);
        ObjectSetInteger(0, "EA_Panel_Title", OBJPROP_FONTSIZE, 11);
        ObjectSetString(0, "EA_Panel_Title", OBJPROP_FONT, "Arial Bold");
    }
    
    // Toggle hint
    ObjectDelete(0, "EA_Toggle_Hint");
    if(ObjectCreate(0, "EA_Toggle_Hint", OBJ_LABEL, 0, 0, 0))
    {
        ObjectSetInteger(0, "EA_Toggle_Hint", OBJPROP_XDISTANCE, panelX + panelWidth - 110);
        ObjectSetInteger(0, "EA_Toggle_Hint", OBJPROP_YDISTANCE, panelY + 10);
        ObjectSetString(0, "EA_Toggle_Hint", OBJPROP_TEXT, "⌨️ Press H to toggle");
        ObjectSetInteger(0, "EA_Toggle_Hint", OBJPROP_COLOR, clrLightGray);
        ObjectSetInteger(0, "EA_Toggle_Hint", OBJPROP_FONTSIZE, 8);
        ObjectSetString(0, "EA_Toggle_Hint", OBJPROP_FONT, "Arial");
    }
    
    UpdateRealTimeDashboard();
}

//+------------------------------------------------------------------+
//| Create Control Buttons with New Layout                          |
//+------------------------------------------------------------------+
void CreateControlButtons()
{
    long btnWidth = 195;  // Wider for 2 buttons
    long btnHeight = 30;
    long btnSpacing = 10;  // Spacing between buttons
    long startX = panelX + 12;
    long startY = panelY + 40;
    
    // Close Profitable Positions button (top left)
    ObjectDelete(0, "Btn_CloseProfits");
    if(ObjectCreate(0, "Btn_CloseProfits", OBJ_BUTTON, 0, 0, 0))
    {
        ObjectSetInteger(0, "Btn_CloseProfits", OBJPROP_XDISTANCE, startX);
        ObjectSetInteger(0, "Btn_CloseProfits", OBJPROP_YDISTANCE, startY);
        ObjectSetInteger(0, "Btn_CloseProfits", OBJPROP_XSIZE, btnWidth);
        ObjectSetInteger(0, "Btn_CloseProfits", OBJPROP_YSIZE, btnHeight);
        ObjectSetString(0, "Btn_CloseProfits", OBJPROP_TEXT, "Close Profits");
        ObjectSetInteger(0, "Btn_CloseProfits", OBJPROP_COLOR, clrWhite);
        ObjectSetInteger(0, "Btn_CloseProfits", OBJPROP_BGCOLOR, clrGreen);
        ObjectSetInteger(0, "Btn_CloseProfits", OBJPROP_FONTSIZE, 9);
        ObjectSetString(0, "Btn_CloseProfits", OBJPROP_FONT, "Arial Bold");
    }
    
    // Pause/Resume Trading button (top right)
    ObjectDelete(0, "Btn_PauseResume");
    if(ObjectCreate(0, "Btn_PauseResume", OBJ_BUTTON, 0, 0, 0))
    {
        ObjectSetInteger(0, "Btn_PauseResume", OBJPROP_XDISTANCE, startX + btnWidth + btnSpacing);
        ObjectSetInteger(0, "Btn_PauseResume", OBJPROP_YDISTANCE, startY);
        ObjectSetInteger(0, "Btn_PauseResume", OBJPROP_XSIZE, btnWidth);
        ObjectSetInteger(0, "Btn_PauseResume", OBJPROP_YSIZE, btnHeight);
        ObjectSetString(0, "Btn_PauseResume", OBJPROP_TEXT, tradingPaused ? "Resume" : "Pause");
        ObjectSetInteger(0, "Btn_PauseResume", OBJPROP_COLOR, clrWhite);
        ObjectSetInteger(0, "Btn_PauseResume", OBJPROP_BGCOLOR, tradingPaused ? clrBlue : clrOrange);
        ObjectSetInteger(0, "Btn_PauseResume", OBJPROP_FONTSIZE, 9);
        ObjectSetString(0, "Btn_PauseResume", OBJPROP_FONT, "Arial Bold");
    }
    
    // Close All Positions button (at bottom of panel)
    ObjectDelete(0, "Btn_CloseAll");
    if(ObjectCreate(0, "Btn_CloseAll", OBJ_BUTTON, 0, 0, 0))
    {
        ObjectSetInteger(0, "Btn_CloseAll", OBJPROP_XDISTANCE, panelX + 60);  // Centered
        ObjectSetInteger(0, "Btn_CloseAll", OBJPROP_YDISTANCE, panelY + panelHeight - 45);  // At bottom
        ObjectSetInteger(0, "Btn_CloseAll", OBJPROP_XSIZE, 300);  // Wide button
        ObjectSetInteger(0, "Btn_CloseAll", OBJPROP_YSIZE, 35);   // Slightly taller
        ObjectSetString(0, "Btn_CloseAll", OBJPROP_TEXT, "CLOSE ALL POSITIONS");
        ObjectSetInteger(0, "Btn_CloseAll", OBJPROP_COLOR, clrWhite);
        ObjectSetInteger(0, "Btn_CloseAll", OBJPROP_BGCOLOR, clrRed);
        ObjectSetInteger(0, "Btn_CloseAll", OBJPROP_FONTSIZE, 10);
        ObjectSetString(0, "Btn_CloseAll", OBJPROP_FONT, "Arial Bold");
    }
}

//+------------------------------------------------------------------+
//| Create Session Lines                                             |
//+------------------------------------------------------------------+
void CreateSessionLines()
{
    // London Session Line
    ObjectDelete(0, "LondonSession_Line");
    if(ObjectCreate(0, "LondonSession_Line", OBJ_VLINE, 0, 0, 0))
    {
        ObjectSetInteger(0, "LondonSession_Line", OBJPROP_COLOR, LondonSessionColor);
        ObjectSetInteger(0, "LondonSession_Line", OBJPROP_STYLE, STYLE_DASH);
        ObjectSetInteger(0, "LondonSession_Line", OBJPROP_WIDTH, 2);
        ObjectSetInteger(0, "LondonSession_Line", OBJPROP_BACK, false);
        ObjectSetInteger(0, "LondonSession_Line", OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, "LondonSession_Line", OBJPROP_HIDDEN, true);
    }
    
    // London Session Label
    ObjectDelete(0, "LondonSession_Label");
    if(ObjectCreate(0, "LondonSession_Label", OBJ_TEXT, 0, 0, 0))
    {
        ObjectSetString(0, "LondonSession_Label", OBJPROP_TEXT, "🇬🇧 London Open");
        ObjectSetInteger(0, "LondonSession_Label", OBJPROP_COLOR, LondonSessionColor);
        ObjectSetInteger(0, "LondonSession_Label", OBJPROP_FONTSIZE, 10);
        ObjectSetString(0, "LondonSession_Label", OBJPROP_FONT, "Arial Bold");
        ObjectSetInteger(0, "LondonSession_Label", OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
    }
    
    // New York Session Line
    ObjectDelete(0, "NewYorkSession_Line");
    if(ObjectCreate(0, "NewYorkSession_Line", OBJ_VLINE, 0, 0, 0))
    {
        ObjectSetInteger(0, "NewYorkSession_Line", OBJPROP_COLOR, NewYorkSessionColor);
        ObjectSetInteger(0, "NewYorkSession_Line", OBJPROP_STYLE, STYLE_DASH);
        ObjectSetInteger(0, "NewYorkSession_Line", OBJPROP_WIDTH, 2);
        ObjectSetInteger(0, "NewYorkSession_Line", OBJPROP_BACK, false);
        ObjectSetInteger(0, "NewYorkSession_Line", OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, "NewYorkSession_Line", OBJPROP_HIDDEN, true);
    }
    
    // New York Session Label
    ObjectDelete(0, "NewYorkSession_Label");
    if(ObjectCreate(0, "NewYorkSession_Label", OBJ_TEXT, 0, 0, 0))
    {
        ObjectSetString(0, "NewYorkSession_Label", OBJPROP_TEXT, "🇺🇸 New York Open");
        ObjectSetInteger(0, "NewYorkSession_Label", OBJPROP_COLOR, NewYorkSessionColor);
        ObjectSetInteger(0, "NewYorkSession_Label", OBJPROP_FONTSIZE, 10);
        ObjectSetString(0, "NewYorkSession_Label", OBJPROP_FONT, "Arial Bold");
        ObjectSetInteger(0, "NewYorkSession_Label", OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
    }
    
    UpdateSessionLines();
}

//+------------------------------------------------------------------+
//| Update Session Lines                                             |
//+------------------------------------------------------------------+
void UpdateSessionLines()
{
    MqlDateTime currentTime;
    TimeToStruct(TimeCurrent(), currentTime);
    
    // Calculate today's session times
    datetime todayLondonOpen = StructToTime(currentTime);
    todayLondonOpen = todayLondonOpen - (currentTime.hour * 3600) - (currentTime.min * 60) - currentTime.sec;
    todayLondonOpen += LondonOpenHour * 3600;
    
    datetime todayNYOpen = StructToTime(currentTime);
    todayNYOpen = todayNYOpen - (currentTime.hour * 3600) - (currentTime.min * 60) - currentTime.sec;
    todayNYOpen += NewYorkOpenHour * 3600;
    
    // Get current price for label positioning
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // Update London Session Line
    ObjectSetInteger(0, "LondonSession_Line", OBJPROP_TIME, todayLondonOpen);
    ObjectSetInteger(0, "LondonSession_Label", OBJPROP_TIME, todayLondonOpen);
    ObjectSetDouble(0, "LondonSession_Label", OBJPROP_PRICE, currentPrice);
    
    // Update New York Session Line  
    ObjectSetInteger(0, "NewYorkSession_Line", OBJPROP_TIME, todayNYOpen);
    ObjectSetInteger(0, "NewYorkSession_Label", OBJPROP_TIME, todayNYOpen);
    ObjectSetDouble(0, "NewYorkSession_Label", OBJPROP_PRICE, currentPrice * 1.001);
}


//+------------------------------------------------------------------+
//| Update Real-time Dashboard with Improved Legibility             |
//+------------------------------------------------------------------+
void UpdateRealTimeDashboard()
{
    if(!panelVisible || !EnableDashboard) return;
    
    // THOROUGH CLEANUP - Remove all dashboard objects
    ObjectDelete(0, "Dashboard_Balance_Value");
    ObjectDelete(0, "Dashboard_Equity_Value");
    ObjectDelete(0, "Dashboard_Buy_Count");
    ObjectDelete(0, "Dashboard_Sell_Count");
    ObjectDelete(0, "Dashboard_DailyPL");
    ObjectDelete(0, "Dashboard_TotalPos");
    ObjectDelete(0, "Dashboard_ProfitSummary");
    ObjectDelete(0, "Dashboard_NetPL");
    ObjectDelete(0, "Dashboard_TP");
    ObjectDelete(0, "Dashboard_Symbol");
    ObjectDelete(0, "Dashboard_Price");
    ObjectDelete(0, "Dashboard_H4Res");
    ObjectDelete(0, "Dashboard_H4Sup");
    ObjectDelete(0, "Dashboard_H1Res");
    ObjectDelete(0, "Dashboard_H1Sup");
    ObjectDelete(0, "Dashboard_SRBehavior");
    ObjectDelete(0, "Dashboard_Reverse");
    
    // Gather account data
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double dailyPL = equity - dailyStartBalance;
    
    // Gather position statistics
    long totalPositions = CountPositions();
    long buyPositions = CountBuyPositions();
    long sellPositions = CountSellPositions();
    long profitablePositions = CountProfitablePositions();
    long losingPositions = CountLosingPositions();
    double totalProfit = GetTotalProfit();
    double currentTPAmount = CalculateTPAmount();
    
    // Calculate metrics
    double dailyROI = dailyStartBalance > 0 ? (dailyPL / dailyStartBalance) * 100.0 : 0.0;
    double buyUtilization = MaxBuyTrades > 0 ? ((double)buyPositions / MaxBuyTrades) * 100.0 : 0.0;
    double sellUtilization = MaxSellTrades > 0 ? ((double)sellPositions / MaxSellTrades) * 100.0 : 0.0;
    
    // Two-column layout configuration with improved spacing
    long leftColumnX = panelX + 18;
    long rightColumnX = panelX + 225;  // Right column starts at middle
    long startY = panelY + 85;  // Start below buttons
    int lineSpacing = 18;  // Improved spacing for better legibility
    int currentLeftLine = 0;
    int currentRightLine = 0;
    
    // LEFT COLUMN - Account & Positions
    // Balance
    string balanceLabel = "Dashboard_Balance_Value";
    if(ObjectCreate(0, balanceLabel, OBJ_LABEL, 0, 0, 0))
    {
        ObjectSetInteger(0, balanceLabel, OBJPROP_XDISTANCE, leftColumnX);
        ObjectSetInteger(0, balanceLabel, OBJPROP_YDISTANCE, startY + (currentLeftLine * lineSpacing));
        ObjectSetString(0, balanceLabel, OBJPROP_TEXT, "Balance: $" + DoubleToString(balance, 2));
        ObjectSetInteger(0, balanceLabel, OBJPROP_COLOR, clrWhite);
        ObjectSetInteger(0, balanceLabel, OBJPROP_FONTSIZE, 11);
        ObjectSetString(0, balanceLabel, OBJPROP_FONT, "Arial Bold");
    }
    currentLeftLine++;
    
    // Equity
    string equityLabel = "Dashboard_Equity_Value";
    if(ObjectCreate(0, equityLabel, OBJ_LABEL, 0, 0, 0))
    {
        ObjectSetInteger(0, equityLabel, OBJPROP_XDISTANCE, leftColumnX);
        ObjectSetInteger(0, equityLabel, OBJPROP_YDISTANCE, startY + (currentLeftLine * lineSpacing));
        ObjectSetString(0, equityLabel, OBJPROP_TEXT, "Equity: $" + DoubleToString(equity, 2));
        ObjectSetInteger(0, equityLabel, OBJPROP_COLOR, clrYellow);
        ObjectSetInteger(0, equityLabel, OBJPROP_FONTSIZE, 11);
        ObjectSetString(0, equityLabel, OBJPROP_FONT, "Arial Bold");
    }
    currentLeftLine++;
    
    // Daily P&L with space
    currentLeftLine++;
    string dailyPLLabel = "Dashboard_DailyPL";
    if(ObjectCreate(0, dailyPLLabel, OBJ_LABEL, 0, 0, 0))
    {
        ObjectSetInteger(0, dailyPLLabel, OBJPROP_XDISTANCE, leftColumnX);
        ObjectSetInteger(0, dailyPLLabel, OBJPROP_YDISTANCE, startY + (currentLeftLine * lineSpacing));
        ObjectSetString(0, dailyPLLabel, OBJPROP_TEXT, "Daily: " + (dailyPL >= 0 ? "+" : "") + DoubleToString(dailyPL, 2) + " (" + (dailyROI >= 0 ? "+" : "") + DoubleToString(dailyROI, 2) + "%)");
        ObjectSetInteger(0, dailyPLLabel, OBJPROP_COLOR, dailyPL >= 0 ? clrLime : clrRed);
        ObjectSetInteger(0, dailyPLLabel, OBJPROP_FONTSIZE, 10);
        ObjectSetString(0, dailyPLLabel, OBJPROP_FONT, "Arial");
    }
    currentLeftLine++;
    
    // Total Positions
    string totalPosLabel = "Dashboard_TotalPos";
    if(ObjectCreate(0, totalPosLabel, OBJ_LABEL, 0, 0, 0))
    {
        ObjectSetInteger(0, totalPosLabel, OBJPROP_XDISTANCE, leftColumnX);
        ObjectSetInteger(0, totalPosLabel, OBJPROP_YDISTANCE, startY + (currentLeftLine * lineSpacing));
        ObjectSetString(0, totalPosLabel, OBJPROP_TEXT, "Total Positions: " + IntegerToString((int)totalPositions));
        ObjectSetInteger(0, totalPosLabel, OBJPROP_COLOR, clrWhite);
        ObjectSetInteger(0, totalPosLabel, OBJPROP_FONTSIZE, 10);
        ObjectSetString(0, totalPosLabel, OBJPROP_FONT, "Arial");
    }
    currentLeftLine++;
    
    // Buy positions
    string buyCountLabel = "Dashboard_Buy_Count";
    if(ObjectCreate(0, buyCountLabel, OBJ_LABEL, 0, 0, 0))
    {
        ObjectSetInteger(0, buyCountLabel, OBJPROP_XDISTANCE, leftColumnX);
        ObjectSetInteger(0, buyCountLabel, OBJPROP_YDISTANCE, startY + (currentLeftLine * lineSpacing));
        ObjectSetString(0, buyCountLabel, OBJPROP_TEXT, "Buy: " + IntegerToString((int)buyPositions) + "/" + IntegerToString((int)MaxBuyTrades) + " (" + DoubleToString(buyUtilization, 0) + "%)");
        ObjectSetInteger(0, buyCountLabel, OBJPROP_COLOR, clrLime);
        ObjectSetInteger(0, buyCountLabel, OBJPROP_FONTSIZE, 10);
        ObjectSetString(0, buyCountLabel, OBJPROP_FONT, "Arial");
    }
    currentLeftLine++;
    
    // Sell positions
    string sellCountLabel = "Dashboard_Sell_Count";
    if(ObjectCreate(0, sellCountLabel, OBJ_LABEL, 0, 0, 0))
    {
        ObjectSetInteger(0, sellCountLabel, OBJPROP_XDISTANCE, leftColumnX);
        ObjectSetInteger(0, sellCountLabel, OBJPROP_YDISTANCE, startY + (currentLeftLine * lineSpacing));
        ObjectSetString(0, sellCountLabel, OBJPROP_TEXT, "Sell: " + IntegerToString((int)sellPositions) + "/" + IntegerToString((int)MaxSellTrades) + " (" + DoubleToString(sellUtilization, 0) + "%)");
        ObjectSetInteger(0, sellCountLabel, OBJPROP_COLOR, clrOrange);
        ObjectSetInteger(0, sellCountLabel, OBJPROP_FONTSIZE, 10);
        ObjectSetString(0, sellCountLabel, OBJPROP_FONT, "Arial");
    }
    currentLeftLine++;
    
    // Add space then Profitability summary
    currentLeftLine++;
    string profitSummaryLabel = "Dashboard_ProfitSummary";
    if(ObjectCreate(0, profitSummaryLabel, OBJ_LABEL, 0, 0, 0))
    {
        ObjectSetInteger(0, profitSummaryLabel, OBJPROP_XDISTANCE, leftColumnX);
        ObjectSetInteger(0, profitSummaryLabel, OBJPROP_YDISTANCE, startY + (currentLeftLine * lineSpacing));
        ObjectSetString(0, profitSummaryLabel, OBJPROP_TEXT, "Profitable: " + IntegerToString((int)profitablePositions) + " | Losing: " + IntegerToString((int)losingPositions));
        ObjectSetInteger(0, profitSummaryLabel, OBJPROP_COLOR, clrWhite);
        ObjectSetInteger(0, profitSummaryLabel, OBJPROP_FONTSIZE, 9);
        ObjectSetString(0, profitSummaryLabel, OBJPROP_FONT, "Arial");
    }
    currentLeftLine++;
    
    // Net P&L
    string netPLLabel = "Dashboard_NetPL";
    if(ObjectCreate(0, netPLLabel, OBJ_LABEL, 0, 0, 0))
    {
        ObjectSetInteger(0, netPLLabel, OBJPROP_XDISTANCE, leftColumnX);
        ObjectSetInteger(0, netPLLabel, OBJPROP_YDISTANCE, startY + (currentLeftLine * lineSpacing));
        ObjectSetString(0, netPLLabel, OBJPROP_TEXT, "Net P&L: " + (totalProfit >= 0 ? "+" : "") + DoubleToString(totalProfit, 2));
        ObjectSetInteger(0, netPLLabel, OBJPROP_COLOR, totalProfit >= 0 ? clrLime : clrRed);
        ObjectSetInteger(0, netPLLabel, OBJPROP_FONTSIZE, 10);
        ObjectSetString(0, netPLLabel, OBJPROP_FONT, "Arial");
    }
    currentLeftLine++;
    
    // Take Profit
    string tpLabel = "Dashboard_TP";
    if(ObjectCreate(0, tpLabel, OBJ_LABEL, 0, 0, 0))
    {
        ObjectSetInteger(0, tpLabel, OBJPROP_XDISTANCE, leftColumnX);
        ObjectSetInteger(0, tpLabel, OBJPROP_YDISTANCE, startY + (currentLeftLine * lineSpacing));
        ObjectSetString(0, tpLabel, OBJPROP_TEXT, "TP: " + DoubleToString(IndividualTradeTP, 1) + "% = $" + DoubleToString(currentTPAmount, 2));
        ObjectSetInteger(0, tpLabel, OBJPROP_COLOR, clrCyan);
        ObjectSetInteger(0, tpLabel, OBJPROP_FONTSIZE, 9);
        ObjectSetString(0, tpLabel, OBJPROP_FONT, "Arial");
    }
    
    // RIGHT COLUMN - Symbol & S/R Information
    // Symbol info
    string symbolLabel = "Dashboard_Symbol";
    if(ObjectCreate(0, symbolLabel, OBJ_LABEL, 0, 0, 0))
    {
        ObjectSetInteger(0, symbolLabel, OBJPROP_XDISTANCE, rightColumnX);
        ObjectSetInteger(0, symbolLabel, OBJPROP_YDISTANCE, startY + (currentRightLine * lineSpacing));
        ObjectSetString(0, symbolLabel, OBJPROP_TEXT, _Symbol + " (" + GetSymbolTypeString() + ")");
        ObjectSetInteger(0, symbolLabel, OBJPROP_COLOR, isCryptoPair ? clrGold : clrCyan);
        ObjectSetInteger(0, symbolLabel, OBJPROP_FONTSIZE, 10);
        ObjectSetString(0, symbolLabel, OBJPROP_FONT, "Arial Bold");
    }
    currentRightLine++;
    
    // Current Price
    string priceLabel = "Dashboard_Price";
    if(ObjectCreate(0, priceLabel, OBJ_LABEL, 0, 0, 0))
    {
        ObjectSetInteger(0, priceLabel, OBJPROP_XDISTANCE, rightColumnX);
        ObjectSetInteger(0, priceLabel, OBJPROP_YDISTANCE, startY + (currentRightLine * lineSpacing));
        ObjectSetString(0, priceLabel, OBJPROP_TEXT, "Price: " + DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
        ObjectSetInteger(0, priceLabel, OBJPROP_COLOR, clrWhite);
        ObjectSetInteger(0, priceLabel, OBJPROP_FONTSIZE, 9);
        ObjectSetString(0, priceLabel, OBJPROP_FONT, "Arial");
    }
    currentRightLine += 2; // Add space
    
    // Support/Resistance Information (if enabled)
    if(EnableSRDetection)
    {
        // H4 Resistance
        string h4ResLabel = "Dashboard_H4Res";
        if(ObjectCreate(0, h4ResLabel, OBJ_LABEL, 0, 0, 0))
        {
            ObjectSetInteger(0, h4ResLabel, OBJPROP_XDISTANCE, rightColumnX);
            ObjectSetInteger(0, h4ResLabel, OBJPROP_YDISTANCE, startY + (currentRightLine * lineSpacing));
            ObjectSetString(0, h4ResLabel, OBJPROP_TEXT, "H4 Res: " + DoubleToString(currentH4Resistance, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
            ObjectSetInteger(0, h4ResLabel, OBJPROP_COLOR, ResistanceColor);
            ObjectSetInteger(0, h4ResLabel, OBJPROP_FONTSIZE, 9);
            ObjectSetString(0, h4ResLabel, OBJPROP_FONT, "Arial");
        }
        currentRightLine++;
        
        // H4 Support
        string h4SupLabel = "Dashboard_H4Sup";
        if(ObjectCreate(0, h4SupLabel, OBJ_LABEL, 0, 0, 0))
        {
            ObjectSetInteger(0, h4SupLabel, OBJPROP_XDISTANCE, rightColumnX);
            ObjectSetInteger(0, h4SupLabel, OBJPROP_YDISTANCE, startY + (currentRightLine * lineSpacing));
            ObjectSetString(0, h4SupLabel, OBJPROP_TEXT, "H4 Sup: " + DoubleToString(currentH4Support, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
            ObjectSetInteger(0, h4SupLabel, OBJPROP_COLOR, SupportColor);
            ObjectSetInteger(0, h4SupLabel, OBJPROP_FONTSIZE, 9);
            ObjectSetString(0, h4SupLabel, OBJPROP_FONT, "Arial");
        }
        currentRightLine++;
        
        // Add space
        currentRightLine++;
        
        // H1 Resistance
        string h1ResLabel = "Dashboard_H1Res";
        if(ObjectCreate(0, h1ResLabel, OBJ_LABEL, 0, 0, 0))
        {
            ObjectSetInteger(0, h1ResLabel, OBJPROP_XDISTANCE, rightColumnX);
            ObjectSetInteger(0, h1ResLabel, OBJPROP_YDISTANCE, startY + (currentRightLine * lineSpacing));
            ObjectSetString(0, h1ResLabel, OBJPROP_TEXT, "H1 Res: " + DoubleToString(currentH1Resistance, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
            ObjectSetInteger(0, h1ResLabel, OBJPROP_COLOR, ResistanceColor);
            ObjectSetInteger(0, h1ResLabel, OBJPROP_FONTSIZE, 9);
            ObjectSetString(0, h1ResLabel, OBJPROP_FONT, "Arial");
        }
        currentRightLine++;
        
        // H1 Support
        string h1SupLabel = "Dashboard_H1Sup";
        if(ObjectCreate(0, h1SupLabel, OBJ_LABEL, 0, 0, 0))
        {
            ObjectSetInteger(0, h1SupLabel, OBJPROP_XDISTANCE, rightColumnX);
            ObjectSetInteger(0, h1SupLabel, OBJPROP_YDISTANCE, startY + (currentRightLine * lineSpacing));
            ObjectSetString(0, h1SupLabel, OBJPROP_TEXT, "H1 Sup: " + DoubleToString(currentH1Support, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
            ObjectSetInteger(0, h1SupLabel, OBJPROP_COLOR, SupportColor);
            ObjectSetInteger(0, h1SupLabel, OBJPROP_FONTSIZE, 9);
            ObjectSetString(0, h1SupLabel, OBJPROP_FONT, "Arial");
        }
        currentRightLine += 2; // Add space
        
        // S/R Behavior (compact)
        string srBehaviorLabel = "Dashboard_SRBehavior";
        if(ObjectCreate(0, srBehaviorLabel, OBJ_LABEL, 0, 0, 0))
        {
            ObjectSetInteger(0, srBehaviorLabel, OBJPROP_XDISTANCE, rightColumnX);
            ObjectSetInteger(0, srBehaviorLabel, OBJPROP_YDISTANCE, startY + (currentRightLine * lineSpacing));
            ObjectSetString(0, srBehaviorLabel, OBJPROP_TEXT, "Pause: B@R=" + (PauseBuyNearResistance ? "Y" : "N") + " S@S=" + (PauseSellNearSupport ? "Y" : "N"));
            ObjectSetInteger(0, srBehaviorLabel, OBJPROP_COLOR, clrGray);
            ObjectSetInteger(0, srBehaviorLabel, OBJPROP_FONTSIZE, 8);
            ObjectSetString(0, srBehaviorLabel, OBJPROP_FONT, "Arial");
        }
        currentRightLine++;
        
        string reverseLabel = "Dashboard_Reverse";
        if(ObjectCreate(0, reverseLabel, OBJ_LABEL, 0, 0, 0))
        {
            ObjectSetInteger(0, reverseLabel, OBJPROP_XDISTANCE, rightColumnX);
            ObjectSetInteger(0, reverseLabel, OBJPROP_YDISTANCE, startY + (currentRightLine * lineSpacing));
            ObjectSetString(0, reverseLabel, OBJPROP_TEXT, "Reverse: " + (ReverseTradingAtSR ? "ON" : "OFF"));
            ObjectSetInteger(0, reverseLabel, OBJPROP_COLOR, ReverseTradingAtSR ? clrLime : clrGray);
            ObjectSetInteger(0, reverseLabel, OBJPROP_FONTSIZE, 8);
            ObjectSetString(0, reverseLabel, OBJPROP_FONT, "Arial");
        }
    }
    
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Toggle Panel Visibility                                         |
//+------------------------------------------------------------------+
void TogglePanelVisibility()
{
    panelVisible = !panelVisible;
    if(panelVisible)
        ShowPanel();
    else
        HidePanel();
}

//+------------------------------------------------------------------+
//| Show Panel                                                       |
//+------------------------------------------------------------------+
void ShowPanel()
{
    panelVisible = true;
    
    string panelObjects[7];
    panelObjects[0] = "EA_Panel_Background";
    panelObjects[1] = "EA_Panel_Header";
    panelObjects[2] = "EA_Panel_Title";
    panelObjects[3] = "EA_Toggle_Hint";
    panelObjects[4] = "Btn_CloseProfits";
    panelObjects[5] = "Btn_CloseAll";
    panelObjects[6] = "Btn_PauseResume";
    
    for(int i = 0; i < 7; i++)
    {
        ObjectSetInteger(0, panelObjects[i], OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
    }
    
    UpdateRealTimeDashboard();
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Hide Panel                                                       |
//+------------------------------------------------------------------+
void HidePanel()
{
    panelVisible = false;
    
    string panelObjects[7];
    panelObjects[0] = "EA_Panel_Background";
    panelObjects[1] = "EA_Panel_Header";
    panelObjects[2] = "EA_Panel_Title";
    panelObjects[3] = "EA_Toggle_Hint";
    panelObjects[4] = "Btn_CloseProfits";
    panelObjects[5] = "Btn_CloseAll";
    panelObjects[6] = "Btn_PauseResume";
    
    for(int i = 0; i < 7; i++)
    {
        ObjectSetInteger(0, panelObjects[i], OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
    }
    
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Detect Symbol Type (Crypto vs Forex)                            |
//+------------------------------------------------------------------+
bool DetectSymbolType()
{
    string symbol = _Symbol;
    
    // Check for crypto symbols
    if(StringFind(symbol, "BTC") >= 0 || StringFind(symbol, "ETH") >= 0 || 
       StringFind(symbol, "XRP") >= 0 || StringFind(symbol, "LTC") >= 0 ||
       StringFind(symbol, "ADA") >= 0 || StringFind(symbol, "DOT") >= 0 ||
       StringFind(symbol, "SOL") >= 0 || StringFind(symbol, "MATIC") >= 0 ||
       StringFind(symbol, "AVAX") >= 0 || StringFind(symbol, "LINK") >= 0)
    {
        isCryptoPair = true;
        symbolType = "CRYPTO";
        Print("🪙 CRYPTO DETECTED: ", symbol);
    }
    else
    {
        isCryptoPair = false;
        symbolType = "FOREX";
        Print("📈 FOREX DETECTED: ", symbol);
    }
    
    return isCryptoPair;
}

//+------------------------------------------------------------------+
//| Calculate TP Amount in USD                                       |
//+------------------------------------------------------------------+
double CalculateTPAmount()
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    if(balance <= 0) balance = 1000;
    return balance * (IndividualTradeTP / 100.0);
}

//+------------------------------------------------------------------+
//| Calculate TP Movement (Crypto Points or Forex Pips)             |
//+------------------------------------------------------------------+
double CalculateTPMovement()
{
    double tpAmountUSD = CalculateTPAmount();
    double lotSize = currentLotSize;
    
    if(isCryptoPair)
    {
        // CRYPTO CALCULATION
        double pointValue = lotSize; // 0.1 lot = $0.10 per point
        
        if(pointValue <= 0)
        {
            Print("⚠️ Crypto point value calculation failed, using minimum");
            return CryptoMinMovement;
        }
        
        double pointsNeeded = tpAmountUSD / pointValue;
        
        // Apply crypto limits
        if(pointsNeeded < CryptoMinMovement) pointsNeeded = CryptoMinMovement;
        if(pointsNeeded > CryptoMaxMovement) pointsNeeded = CryptoMaxMovement;
        
        Print("🪙 Crypto TP Calc: $", DoubleToString(tpAmountUSD, 2), " ÷ $", DoubleToString(pointValue, 2), "/point = ", DoubleToString(pointsNeeded, 2), " points");
        
        return pointsNeeded;
    }
    else
    {
        // FOREX CALCULATION
        double pipValue = lotSize * 10.0; // Standard forex calculation
        
        if(pipValue <= 0)
        {
            return (double)TPPipsBackup;
        }
        
        double pipsNeeded = tpAmountUSD / pipValue;
        
        // Apply forex limits
        if(pipsNeeded < 5) pipsNeeded = 5;
        if(pipsNeeded > 500) pipsNeeded = 500;
        
        return pipsNeeded;
    }
}

//+------------------------------------------------------------------+
//| Calculate TP Price Level                                         |
//+------------------------------------------------------------------+
double CalculateTPPrice(bool isBuy, double openPrice)
{
    double tpMovement = CalculateTPMovement();
    long digits = SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    double tpPrice;
    
    if(isCryptoPair)
    {
        // CRYPTO: Direct point movement
        if(isBuy)
            tpPrice = openPrice + tpMovement;
        else
            tpPrice = openPrice - tpMovement;
    }
    else
    {
        // FOREX: Use pip size calculation
        double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
        double pipSize = point;
        if(digits == 5 || digits == 3)
            pipSize = point * 10;
        
        if(isBuy)
            tpPrice = openPrice + (tpMovement * pipSize);
        else
            tpPrice = openPrice - (tpMovement * pipSize);
    }
    
    return NormalizeDouble(tpPrice, (int)digits);
}

//+------------------------------------------------------------------+
//| Get Symbol Type String                                           |
//+------------------------------------------------------------------+
string GetSymbolTypeString()
{
    return symbolType;
}

//+------------------------------------------------------------------+
//| Check Percentage-based Take Profit                              |
//+------------------------------------------------------------------+
void CheckPercentageBasedTP()
{
    double tpAmount = CalculateTPAmount();
    int totalPositions = PositionsTotal();
    
    for(int i = totalPositions - 1; i >= 0; i--)
    {
        if(PositionGetSymbol(i) == _Symbol && 
           PositionGetInteger(POSITION_MAGIC) == (long)MagicNumber)
        {
            double profit = PositionGetDouble(POSITION_PROFIT);
            ulong ticket = PositionGetTicket(i);
            
            if(profit >= tpAmount)
            {
                if(trade.PositionClose(ticket))
                {
                    Print("🎯 PERCENTAGE TP HIT: #", ticket, " | $", DoubleToString(profit, 2));
                    PlayAlertSound("ok.wav");
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Close All Profitable Positions                                  |
//+------------------------------------------------------------------+
bool CloseAllProfitablePositions()
{
    int closedCount = 0;
    int totalPositions = PositionsTotal();
    
    for(int i = totalPositions - 1; i >= 0; i--)
    {
        if(PositionGetSymbol(i) == _Symbol && 
           PositionGetInteger(POSITION_MAGIC) == (long)MagicNumber)
        {
            double profit = PositionGetDouble(POSITION_PROFIT);
            if(profit > 0)
            {
                ulong ticket = PositionGetTicket(i);
                if(trade.PositionClose(ticket))
                {
                    closedCount++;
                    Print("💰 Profitable position #", ticket, " closed: +$", DoubleToString(profit, 2));
                }
            }
        }
    }
    
    if(closedCount > 0)
    {
        Print("✅ ", closedCount, " profitable positions closed");
        PlayAlertSound("ok.wav");
        UpdateRealTimeDashboard();
    }
    
    return closedCount > 0;
}

//+------------------------------------------------------------------+
//| Close All Positions                                             |
//+------------------------------------------------------------------+
bool CloseAllTrades()
{
    int closedCount = 0;
    int totalPositions = PositionsTotal();
    
    for(int i = totalPositions - 1; i >= 0; i--)
    {
        if(PositionGetSymbol(i) == _Symbol && 
           PositionGetInteger(POSITION_MAGIC) == (long)MagicNumber)
        {
            ulong ticket = PositionGetTicket(i);
            if(trade.PositionClose(ticket))
                closedCount++;
        }
    }
    
    if(closedCount > 0)
    {
        Print("✅ ", closedCount, " positions closed");
        PlayAlertSound("alert.wav");
        UpdateRealTimeDashboard();
    }
    
    return closedCount > 0;
}

//+------------------------------------------------------------------+
//| Position Counting Functions                                      |
//+------------------------------------------------------------------+
long CountPositions()
{
    long count = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(PositionGetSymbol(i) == _Symbol && 
           PositionGetInteger(POSITION_MAGIC) == (long)MagicNumber)
            count++;
    }
    return count;
}

long CountBuyPositions()
{
    long count = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(PositionGetSymbol(i) == _Symbol && 
           PositionGetInteger(POSITION_MAGIC) == (long)MagicNumber &&
           PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            count++;
    }
    return count;
}

long CountSellPositions()
{
    long count = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(PositionGetSymbol(i) == _Symbol && 
           PositionGetInteger(POSITION_MAGIC) == (long)MagicNumber &&
           PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
            count++;
    }
    return count;
}

long CountProfitablePositions()
{
    long count = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(PositionGetSymbol(i) == _Symbol && 
           PositionGetInteger(POSITION_MAGIC) == (long)MagicNumber &&
           PositionGetDouble(POSITION_PROFIT) > 0)
            count++;
    }
    return count;
}

long CountLosingPositions()
{
    long count = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(PositionGetSymbol(i) == _Symbol && 
           PositionGetInteger(POSITION_MAGIC) == (long)MagicNumber &&
           PositionGetDouble(POSITION_PROFIT) < 0)
            count++;
    }
    return count;
}

double GetTotalProfit()
{
    double totalProfit = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(PositionGetSymbol(i) == _Symbol && 
           PositionGetInteger(POSITION_MAGIC) == (long)MagicNumber)
        {
            totalProfit += PositionGetDouble(POSITION_PROFIT);
        }
    }
    return totalProfit;
}

//+------------------------------------------------------------------+
//| Calculate Current Drawdown                                       |
//+------------------------------------------------------------------+
double GetCurrentDrawdown()
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    if(balance <= 0 || dailyStartBalance <= 0) return 0.0;
    
    if(equity < dailyStartBalance)
    {
        return ((dailyStartBalance - equity) / dailyStartBalance) * 100.0;
    }
    return 0.0;
}

//+------------------------------------------------------------------+
//| Normalize Lot Size                                               |
//+------------------------------------------------------------------+
double NormalizeLotSize(double lotSize)
{
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    if(lotSize < minLot) lotSize = minLot;
    if(lotSize > maxLot) lotSize = maxLot;
    
    return NormalizeDouble(lotSize / lotStep, 0) * lotStep;
}

//+------------------------------------------------------------------+
//| String Helper Functions                                          |
//+------------------------------------------------------------------+
string GetTradeDirectionString()
{
    switch(TradeDirection)
    {
        case TRADE_BUY_ONLY: return "📈 Buy Only";
        case TRADE_SELL_ONLY: return "📉 Sell Only";
        case TRADE_BOTH_SIDES: return "🔄 Both Directions";
        default: return "❓ Unknown";
    }
}

string GetTimeframeString()
{
    return EnumToString(TradingTimeframe);
}

//+------------------------------------------------------------------+
//| Validate All Input Parameters                                    |
//+------------------------------------------------------------------+
bool ValidateAllInputs()
{
    bool isValid = true;
    
    if(InitialLotSize <= 0)
    {
        Print("❌ ERROR: Initial lot size must be greater than 0");
        isValid = false;
    }
    
    if(IndividualTradeTP <= 0 || IndividualTradeTP > 100)
    {
        Print("❌ ERROR: Individual TP percentage must be between 0.1% and 100%");
        isValid = false;
    }
    
    if(TPPipsBackup <= 0 || TPPipsBackup > 2000)
    {
        Print("❌ ERROR: Backup TP pips must be between 1 and 2000");
        isValid = false;
    }
    
    if(DrawdownLimit <= 0 || DrawdownLimit > 100)
    {
        Print("❌ ERROR: Drawdown limit must be between 1% and 100%");
        isValid = false;
    }
    
    if(MaxBuyTrades <= 0 || MaxBuyTrades > 1000)
    {
        Print("❌ ERROR: Maximum buy trades must be between 1 and 1000");
        isValid = false;
    }
    
    if(MaxSellTrades <= 0 || MaxSellTrades > 1000)
    {
        Print("❌ ERROR: Maximum sell trades must be between 1 and 1000");
        isValid = false;
    }
    
    if(CryptoMinMovement <= 0 || CryptoMaxMovement <= CryptoMinMovement)
    {
        Print("❌ ERROR: Invalid crypto movement settings");
        isValid = false;
    }
    
    if(SRProximityPercent <= 0 || SRProximityPercent > 10)
    {
        Print("❌ ERROR: S/R Proximity must be between 0.01% and 10%");
        isValid = false;
    }
    
    if(SRLookbackBars < 20 || SRLookbackBars > 500)
    {
        Print("❌ ERROR: S/R Lookback bars must be between 20 and 500");
        isValid = false;
    }
    
    if(!isValid) return false;
    
    currentLotSize = NormalizeLotSize(InitialLotSize);
    if(currentLotSize != InitialLotSize)
    {
        Print("ℹ️ Lot size adjusted from ", InitialLotSize, " to ", currentLotSize);
    }
    
    Print("✅ All input parameters validated successfully");
    Print("💰 TP Method: ", IndividualTradeTP, "% = $", DoubleToString(CalculateTPAmount(), 2));
    
    if(isCryptoPair)
    {
        Print("🪙 Crypto Movement: ", DoubleToString(CalculateTPMovement(), 2), " points");
    }
    else
    {
        Print("📈 Forex Movement: ", DoubleToString(CalculateTPMovement(), 1), " pips");
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Play Alert Sound                                                 |
//+------------------------------------------------------------------+
void PlayAlertSound(string soundFile)
{
    if(EnableSounds)
    {
        // PlaySound(soundFile);
    }
}