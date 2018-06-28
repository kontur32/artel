module namespace score = "http://karlowka.de/score";
declare variable $score:db-name := 'artel' ;
declare variable $score:indicators := 
                                      map{
                                        "persons": "Участник", 
                                        "first": "Общая оценка", 
                                        "second": "Внешняя оценка", 
                                        "self_evaluation": "Самооценка", 
                                        "diff": "Пере-(недо-)оценка", 
                                        "penalty": "'Штраф' за пере-(недо-)оценку", 
                                        "penalty_index": "Коэфф. 'штрафа'", 
                                        "second_2": "Оценка коррект.", 
                                        "final_evaluation": "Итоговая оценка в %"
                                      };

declare function score:result($board as node()) 
{
  let $data := $board//values
  let $first := score:first($board)
  let $second := score:second($board)
  let $self_evaluation := 
    for $i in $data
    return number($i/child::*[@имя/data()=$i/@person/data()]/data())
  let $diff := 
    for $i in 1 to count($second)
    return round ($second[$i] - $self_evaluation[$i], 2)
  let $diff_2 :=
    for $i in 1 to count($diff)
    return if ($diff[$i]<0) then (abs($diff[$i])*2) else ($diff[$i])
  let $diff_summ := sum($diff_2)
  let $penalty_index :=
    for $i in 1 to count ($second)
    return round ((1- $diff_2[$i] div $diff_summ), 2)
  let $second_2 := 
    for $i in 1 to count ($second)
    return round ($second[$i]*$penalty_index[$i], 1)
  let $second_final := 
    for $i in 1 to count ($second_2)
    return round ($second_2[$i] div sum($second_2) * 100, 1)
  return 
    map{
      "persons" : $board//members/member/text(), 
      "first" : $first, 
      "second" : $second, 
      "self_evaluation" : $self_evaluation, 
      "diff" : $diff, 
      "penalty" : $diff_2, 
      "penalty_index" : $penalty_index,
      "second_2": $second_2, 
      "final_evaluation": $second_final
    }
};

declare function score:final-table ($evaluations, $columns)
{
  <table border="2px">
    <tr>
      {
        for $i in $columns
        return <td>{map:get($score:indicators, $i)}</td>
      }
    </tr>
    {
      for $i in 1 to count(map:get($evaluations, $columns[1]))
      return 
          <tr>{
            for $a in $columns
            return
              <td>{map:get($evaluations, $a)[$i]}</td>
         }</tr>
    }
  </table>
};

declare function score:first($data)
{
  let $score :=
    for $i in $data/members/member/text()
    return sum($data/values/row[@имя=$i]/data())
  let $summ := sum($score)
  
  for $i in  $score
  return 
    round (($i div $summ)*100, 1)
};

declare function score:second($data)
{
  let $score :=
    for $i in $data/members/member/text()
    return sum($data/values[@person != $i]/row[@имя=$i]/data())

  let $summ := sum($score)
  
  for $i in $score
  return round (($i div $summ)*100, 1) 
};

declare function score:complete ($common as xs:string) as xs:integer
{
   count(db:open($score:db-name)/main/board[@common=$common]/values[row])
};

declare function score:is-complete ($common as xs:string)
{
   let $data := db:open($score:db-name)/main/board[@common=$common]
   let $members-count := count($data//member[text()])
   let $values-count := count($data//values[count(row) > 0])
   return if (  $values-count >= $members-count and  $members-count !=0) then (true()) else (false())
};