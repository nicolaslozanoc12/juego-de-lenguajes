# Generated from CuatroLlanero.g4 by ANTLR 4.13.2
# encoding: utf-8
from antlr4 import *
from io import StringIO
import sys
if sys.version_info[1] > 5:
	from typing import TextIO
else:
	from typing.io import TextIO

def serializedATN():
    return [
        4,1,6,74,2,0,7,0,2,1,7,1,2,2,7,2,2,3,7,3,2,4,7,4,2,5,7,5,2,6,7,6,
        2,7,7,7,2,8,7,8,1,0,1,0,1,0,1,1,1,1,1,1,1,1,1,1,1,1,3,1,28,8,1,1,
        2,1,2,1,2,1,2,1,2,1,2,1,3,1,3,1,3,1,3,1,3,1,3,1,4,1,4,1,4,1,4,1,
        4,1,4,1,5,1,5,1,5,1,5,1,5,1,5,1,6,1,6,1,6,1,6,1,6,1,6,1,7,1,7,1,
        7,1,7,1,7,1,8,1,8,1,8,1,8,1,8,1,8,1,8,3,8,72,8,8,1,8,0,0,9,0,2,4,
        6,8,10,12,14,16,0,0,70,0,18,1,0,0,0,2,27,1,0,0,0,4,29,1,0,0,0,6,
        35,1,0,0,0,8,41,1,0,0,0,10,47,1,0,0,0,12,53,1,0,0,0,14,59,1,0,0,
        0,16,71,1,0,0,0,18,19,3,2,1,0,19,20,5,0,0,1,20,1,1,0,0,0,21,28,3,
        4,2,0,22,28,3,6,3,0,23,28,3,8,4,0,24,28,3,10,5,0,25,28,3,12,6,0,
        26,28,3,14,7,0,27,21,1,0,0,0,27,22,1,0,0,0,27,23,1,0,0,0,27,24,1,
        0,0,0,27,25,1,0,0,0,27,26,1,0,0,0,28,3,1,0,0,0,29,30,5,1,0,0,30,
        31,5,3,0,0,31,32,5,3,0,0,32,33,5,1,0,0,33,34,5,5,0,0,34,5,1,0,0,
        0,35,36,5,4,0,0,36,37,5,2,0,0,37,38,5,3,0,0,38,39,5,4,0,0,39,40,
        5,5,0,0,40,7,1,0,0,0,41,42,5,1,0,0,42,43,5,2,0,0,43,44,5,3,0,0,44,
        45,5,1,0,0,45,46,5,5,0,0,46,9,1,0,0,0,47,48,5,2,0,0,48,49,5,3,0,
        0,49,50,5,2,0,0,50,51,5,3,0,0,51,52,5,5,0,0,52,11,1,0,0,0,53,54,
        5,1,0,0,54,55,5,4,0,0,55,56,5,2,0,0,56,57,5,1,0,0,57,58,5,5,0,0,
        58,13,1,0,0,0,59,60,5,1,0,0,60,61,5,3,0,0,61,62,3,16,8,0,62,63,5,
        5,0,0,63,15,1,0,0,0,64,65,5,2,0,0,65,66,5,3,0,0,66,72,5,1,0,0,67,
        68,5,2,0,0,68,69,5,3,0,0,69,70,5,1,0,0,70,72,3,16,8,0,71,64,1,0,
        0,0,71,67,1,0,0,0,72,17,1,0,0,0,2,27,71
    ]

class CuatroLlaneroParser ( Parser ):

    grammarFileName = "CuatroLlanero.g4"

    atn = ATNDeserializer().deserialize(serializedATN())

    decisionsToDFA = [ DFA(ds, i) for i, ds in enumerate(atn.decisionToState) ]

    sharedContextCache = PredictionContextCache()

    literalNames = [ "<INVALID>", "'T'", "'S'", "'D'", "'M'", "'F'" ]

    symbolicNames = [ "<INVALID>", "TONICA", "SUBDOM", "DOMINANTE", "MENOR", 
                      "FRENAO", "WS" ]

    RULE_ejecucion = 0
    RULE_golpe = 1
    RULE_gaban = 2
    RULE_pajarillo = 3
    RULE_seisPorDerecho = 4
    RULE_zumbeYZumbe = 5
    RULE_tonada = 6
    RULE_contrapunteo = 7
    RULE_bordoneo = 8

    ruleNames =  [ "ejecucion", "golpe", "gaban", "pajarillo", "seisPorDerecho", 
                   "zumbeYZumbe", "tonada", "contrapunteo", "bordoneo" ]

    EOF = Token.EOF
    TONICA=1
    SUBDOM=2
    DOMINANTE=3
    MENOR=4
    FRENAO=5
    WS=6

    def __init__(self, input:TokenStream, output:TextIO = sys.stdout):
        super().__init__(input, output)
        self.checkVersion("4.13.2")
        self._interp = ParserATNSimulator(self, self.atn, self.decisionsToDFA, self.sharedContextCache)
        self._predicates = None




    class EjecucionContext(ParserRuleContext):
        __slots__ = 'parser'

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def golpe(self):
            return self.getTypedRuleContext(CuatroLlaneroParser.GolpeContext,0)


        def EOF(self):
            return self.getToken(CuatroLlaneroParser.EOF, 0)

        def getRuleIndex(self):
            return CuatroLlaneroParser.RULE_ejecucion

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterEjecucion" ):
                listener.enterEjecucion(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitEjecucion" ):
                listener.exitEjecucion(self)




    def ejecucion(self):

        localctx = CuatroLlaneroParser.EjecucionContext(self, self._ctx, self.state)
        self.enterRule(localctx, 0, self.RULE_ejecucion)
        try:
            self.enterOuterAlt(localctx, 1)
            self.state = 18
            self.golpe()
            self.state = 19
            self.match(CuatroLlaneroParser.EOF)
        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx


    class GolpeContext(ParserRuleContext):
        __slots__ = 'parser'

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def gaban(self):
            return self.getTypedRuleContext(CuatroLlaneroParser.GabanContext,0)


        def pajarillo(self):
            return self.getTypedRuleContext(CuatroLlaneroParser.PajarilloContext,0)


        def seisPorDerecho(self):
            return self.getTypedRuleContext(CuatroLlaneroParser.SeisPorDerechoContext,0)


        def zumbeYZumbe(self):
            return self.getTypedRuleContext(CuatroLlaneroParser.ZumbeYZumbeContext,0)


        def tonada(self):
            return self.getTypedRuleContext(CuatroLlaneroParser.TonadaContext,0)


        def contrapunteo(self):
            return self.getTypedRuleContext(CuatroLlaneroParser.ContrapunteoContext,0)


        def getRuleIndex(self):
            return CuatroLlaneroParser.RULE_golpe

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterGolpe" ):
                listener.enterGolpe(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitGolpe" ):
                listener.exitGolpe(self)




    def golpe(self):

        localctx = CuatroLlaneroParser.GolpeContext(self, self._ctx, self.state)
        self.enterRule(localctx, 2, self.RULE_golpe)
        try:
            self.state = 27
            self._errHandler.sync(self)
            la_ = self._interp.adaptivePredict(self._input,0,self._ctx)
            if la_ == 1:
                self.enterOuterAlt(localctx, 1)
                self.state = 21
                self.gaban()
                pass

            elif la_ == 2:
                self.enterOuterAlt(localctx, 2)
                self.state = 22
                self.pajarillo()
                pass

            elif la_ == 3:
                self.enterOuterAlt(localctx, 3)
                self.state = 23
                self.seisPorDerecho()
                pass

            elif la_ == 4:
                self.enterOuterAlt(localctx, 4)
                self.state = 24
                self.zumbeYZumbe()
                pass

            elif la_ == 5:
                self.enterOuterAlt(localctx, 5)
                self.state = 25
                self.tonada()
                pass

            elif la_ == 6:
                self.enterOuterAlt(localctx, 6)
                self.state = 26
                self.contrapunteo()
                pass


        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx


    class GabanContext(ParserRuleContext):
        __slots__ = 'parser'

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def TONICA(self, i:int=None):
            if i is None:
                return self.getTokens(CuatroLlaneroParser.TONICA)
            else:
                return self.getToken(CuatroLlaneroParser.TONICA, i)

        def DOMINANTE(self, i:int=None):
            if i is None:
                return self.getTokens(CuatroLlaneroParser.DOMINANTE)
            else:
                return self.getToken(CuatroLlaneroParser.DOMINANTE, i)

        def FRENAO(self):
            return self.getToken(CuatroLlaneroParser.FRENAO, 0)

        def getRuleIndex(self):
            return CuatroLlaneroParser.RULE_gaban

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterGaban" ):
                listener.enterGaban(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitGaban" ):
                listener.exitGaban(self)




    def gaban(self):

        localctx = CuatroLlaneroParser.GabanContext(self, self._ctx, self.state)
        self.enterRule(localctx, 4, self.RULE_gaban)
        try:
            self.enterOuterAlt(localctx, 1)
            self.state = 29
            self.match(CuatroLlaneroParser.TONICA)
            self.state = 30
            self.match(CuatroLlaneroParser.DOMINANTE)
            self.state = 31
            self.match(CuatroLlaneroParser.DOMINANTE)
            self.state = 32
            self.match(CuatroLlaneroParser.TONICA)
            self.state = 33
            self.match(CuatroLlaneroParser.FRENAO)
        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx


    class PajarilloContext(ParserRuleContext):
        __slots__ = 'parser'

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def MENOR(self, i:int=None):
            if i is None:
                return self.getTokens(CuatroLlaneroParser.MENOR)
            else:
                return self.getToken(CuatroLlaneroParser.MENOR, i)

        def SUBDOM(self):
            return self.getToken(CuatroLlaneroParser.SUBDOM, 0)

        def DOMINANTE(self):
            return self.getToken(CuatroLlaneroParser.DOMINANTE, 0)

        def FRENAO(self):
            return self.getToken(CuatroLlaneroParser.FRENAO, 0)

        def getRuleIndex(self):
            return CuatroLlaneroParser.RULE_pajarillo

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterPajarillo" ):
                listener.enterPajarillo(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitPajarillo" ):
                listener.exitPajarillo(self)




    def pajarillo(self):

        localctx = CuatroLlaneroParser.PajarilloContext(self, self._ctx, self.state)
        self.enterRule(localctx, 6, self.RULE_pajarillo)
        try:
            self.enterOuterAlt(localctx, 1)
            self.state = 35
            self.match(CuatroLlaneroParser.MENOR)
            self.state = 36
            self.match(CuatroLlaneroParser.SUBDOM)
            self.state = 37
            self.match(CuatroLlaneroParser.DOMINANTE)
            self.state = 38
            self.match(CuatroLlaneroParser.MENOR)
            self.state = 39
            self.match(CuatroLlaneroParser.FRENAO)
        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx


    class SeisPorDerechoContext(ParserRuleContext):
        __slots__ = 'parser'

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def TONICA(self, i:int=None):
            if i is None:
                return self.getTokens(CuatroLlaneroParser.TONICA)
            else:
                return self.getToken(CuatroLlaneroParser.TONICA, i)

        def SUBDOM(self):
            return self.getToken(CuatroLlaneroParser.SUBDOM, 0)

        def DOMINANTE(self):
            return self.getToken(CuatroLlaneroParser.DOMINANTE, 0)

        def FRENAO(self):
            return self.getToken(CuatroLlaneroParser.FRENAO, 0)

        def getRuleIndex(self):
            return CuatroLlaneroParser.RULE_seisPorDerecho

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterSeisPorDerecho" ):
                listener.enterSeisPorDerecho(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitSeisPorDerecho" ):
                listener.exitSeisPorDerecho(self)




    def seisPorDerecho(self):

        localctx = CuatroLlaneroParser.SeisPorDerechoContext(self, self._ctx, self.state)
        self.enterRule(localctx, 8, self.RULE_seisPorDerecho)
        try:
            self.enterOuterAlt(localctx, 1)
            self.state = 41
            self.match(CuatroLlaneroParser.TONICA)
            self.state = 42
            self.match(CuatroLlaneroParser.SUBDOM)
            self.state = 43
            self.match(CuatroLlaneroParser.DOMINANTE)
            self.state = 44
            self.match(CuatroLlaneroParser.TONICA)
            self.state = 45
            self.match(CuatroLlaneroParser.FRENAO)
        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx


    class ZumbeYZumbeContext(ParserRuleContext):
        __slots__ = 'parser'

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def SUBDOM(self, i:int=None):
            if i is None:
                return self.getTokens(CuatroLlaneroParser.SUBDOM)
            else:
                return self.getToken(CuatroLlaneroParser.SUBDOM, i)

        def DOMINANTE(self, i:int=None):
            if i is None:
                return self.getTokens(CuatroLlaneroParser.DOMINANTE)
            else:
                return self.getToken(CuatroLlaneroParser.DOMINANTE, i)

        def FRENAO(self):
            return self.getToken(CuatroLlaneroParser.FRENAO, 0)

        def getRuleIndex(self):
            return CuatroLlaneroParser.RULE_zumbeYZumbe

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterZumbeYZumbe" ):
                listener.enterZumbeYZumbe(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitZumbeYZumbe" ):
                listener.exitZumbeYZumbe(self)




    def zumbeYZumbe(self):

        localctx = CuatroLlaneroParser.ZumbeYZumbeContext(self, self._ctx, self.state)
        self.enterRule(localctx, 10, self.RULE_zumbeYZumbe)
        try:
            self.enterOuterAlt(localctx, 1)
            self.state = 47
            self.match(CuatroLlaneroParser.SUBDOM)
            self.state = 48
            self.match(CuatroLlaneroParser.DOMINANTE)
            self.state = 49
            self.match(CuatroLlaneroParser.SUBDOM)
            self.state = 50
            self.match(CuatroLlaneroParser.DOMINANTE)
            self.state = 51
            self.match(CuatroLlaneroParser.FRENAO)
        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx


    class TonadaContext(ParserRuleContext):
        __slots__ = 'parser'

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def TONICA(self, i:int=None):
            if i is None:
                return self.getTokens(CuatroLlaneroParser.TONICA)
            else:
                return self.getToken(CuatroLlaneroParser.TONICA, i)

        def MENOR(self):
            return self.getToken(CuatroLlaneroParser.MENOR, 0)

        def SUBDOM(self):
            return self.getToken(CuatroLlaneroParser.SUBDOM, 0)

        def FRENAO(self):
            return self.getToken(CuatroLlaneroParser.FRENAO, 0)

        def getRuleIndex(self):
            return CuatroLlaneroParser.RULE_tonada

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterTonada" ):
                listener.enterTonada(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitTonada" ):
                listener.exitTonada(self)




    def tonada(self):

        localctx = CuatroLlaneroParser.TonadaContext(self, self._ctx, self.state)
        self.enterRule(localctx, 12, self.RULE_tonada)
        try:
            self.enterOuterAlt(localctx, 1)
            self.state = 53
            self.match(CuatroLlaneroParser.TONICA)
            self.state = 54
            self.match(CuatroLlaneroParser.MENOR)
            self.state = 55
            self.match(CuatroLlaneroParser.SUBDOM)
            self.state = 56
            self.match(CuatroLlaneroParser.TONICA)
            self.state = 57
            self.match(CuatroLlaneroParser.FRENAO)
        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx


    class ContrapunteoContext(ParserRuleContext):
        __slots__ = 'parser'

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def TONICA(self):
            return self.getToken(CuatroLlaneroParser.TONICA, 0)

        def DOMINANTE(self):
            return self.getToken(CuatroLlaneroParser.DOMINANTE, 0)

        def bordoneo(self):
            return self.getTypedRuleContext(CuatroLlaneroParser.BordoneoContext,0)


        def FRENAO(self):
            return self.getToken(CuatroLlaneroParser.FRENAO, 0)

        def getRuleIndex(self):
            return CuatroLlaneroParser.RULE_contrapunteo

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterContrapunteo" ):
                listener.enterContrapunteo(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitContrapunteo" ):
                listener.exitContrapunteo(self)




    def contrapunteo(self):

        localctx = CuatroLlaneroParser.ContrapunteoContext(self, self._ctx, self.state)
        self.enterRule(localctx, 14, self.RULE_contrapunteo)
        try:
            self.enterOuterAlt(localctx, 1)
            self.state = 59
            self.match(CuatroLlaneroParser.TONICA)
            self.state = 60
            self.match(CuatroLlaneroParser.DOMINANTE)
            self.state = 61
            self.bordoneo()
            self.state = 62
            self.match(CuatroLlaneroParser.FRENAO)
        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx


    class BordoneoContext(ParserRuleContext):
        __slots__ = 'parser'

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def SUBDOM(self):
            return self.getToken(CuatroLlaneroParser.SUBDOM, 0)

        def DOMINANTE(self):
            return self.getToken(CuatroLlaneroParser.DOMINANTE, 0)

        def TONICA(self):
            return self.getToken(CuatroLlaneroParser.TONICA, 0)

        def bordoneo(self):
            return self.getTypedRuleContext(CuatroLlaneroParser.BordoneoContext,0)


        def getRuleIndex(self):
            return CuatroLlaneroParser.RULE_bordoneo

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterBordoneo" ):
                listener.enterBordoneo(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitBordoneo" ):
                listener.exitBordoneo(self)




    def bordoneo(self):

        localctx = CuatroLlaneroParser.BordoneoContext(self, self._ctx, self.state)
        self.enterRule(localctx, 16, self.RULE_bordoneo)
        try:
            self.state = 71
            self._errHandler.sync(self)
            la_ = self._interp.adaptivePredict(self._input,1,self._ctx)
            if la_ == 1:
                self.enterOuterAlt(localctx, 1)
                self.state = 64
                self.match(CuatroLlaneroParser.SUBDOM)
                self.state = 65
                self.match(CuatroLlaneroParser.DOMINANTE)
                self.state = 66
                self.match(CuatroLlaneroParser.TONICA)
                pass

            elif la_ == 2:
                self.enterOuterAlt(localctx, 2)
                self.state = 67
                self.match(CuatroLlaneroParser.SUBDOM)
                self.state = 68
                self.match(CuatroLlaneroParser.DOMINANTE)
                self.state = 69
                self.match(CuatroLlaneroParser.TONICA)
                self.state = 70
                self.bordoneo()
                pass


        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx





