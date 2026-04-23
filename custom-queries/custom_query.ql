/**
 * @name Taint propagation from network byte swap to memcpy
 * @description I dati non validati provenienti dalla rete (ntohl, ntohs) raggiungono l'argomento della lunghezza di memcpy, rischiando un buffer overflow.
 * @kind path-problem
 * @problem.severity error
 * @id cpp/uboot/network-byteswap-to-memcpy
 */

 import cpp
 import semmle.code.cpp.dataflow.TaintTracking
 import semmle.code.cpp.controlflow.Guards
 
 class NetworkByteSwap extends Expr {
   // TODO: copy from previous step
   NetworkByteSwap() {
    exists (MacroInvocation i | i.getMacro().getName() in ["ntohs" , "ntohl", "ntohll"] and this = i.getExpr() )
    }
 }
 
 module MyConfig implements DataFlow::ConfigSig {
 
   predicate isSource(DataFlow::Node source) {
     // TODO
        source.asExpr() instanceof NetworkByteSwap
     
   }
   predicate isSink(DataFlow::Node sink) {
    // TODO
    exists(
     FunctionCall c | c.getTarget().hasName("memcpy") and
       sink.asExpr() = c.getArgument(2)
    )
  }


   predicate isBarrier(DataFlow::Node barrier) {
        // TODO
        exists(RelationalOperation cmp |
        (cmp instanceof GTExpr or cmp instanceof GEExpr) and
          cmp.getLeftOperand().(VariableAccess).getTarget() = barrier.asExpr().(VariableAccess).getTarget() 
      )
    }
}
 
 module MyTaint = TaintTracking::Global<MyConfig>;
 import MyTaint::PathGraph
 
 from MyTaint::PathNode source, MyTaint::PathNode sink
 where MyTaint::flowPath(source, sink) 
 select sink, source, sink, "Network byte swap flows to memcpy"
