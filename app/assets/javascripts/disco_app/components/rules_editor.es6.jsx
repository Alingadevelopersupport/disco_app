/**
 * Defines a generic RulesEditor class. This class can't be used directly, but
 * should be inherited, with the inheriting class defining a list of column
 * types and correponding relations and condition data types, like so:
 *
 *    class MyRulesEditor extends RulesEditor {};
 *    MyRulesEditor.defaultProps = {
 *      columns: {
 *        title: {
 *        label: 'Product title',
 *        column: 'title',
 *        relations: {
 *          is_equal_to: {
 *            label: 'is equal to',
 *            relation: 'is_equal_to',
 *            type: 'text'
 *          }
 *        }
 *      }
 *    }
 */
class RulesEditor extends React.Component {

  /**
   * Initialise the Rules Editor, and set the initial state.
   * @param props
   */
  constructor(props) {
    super(props);
    this.state = {
      rules: props.rules
    }
  }

  /**
   * Add a new rule, with an immutable state change.
   */
  onAddRule() {
    const column = Object.keys(this.props.columns)[0];
    const relation = this.getNextRelation(column);
    const condition = this.getNextCondition(column, relation);

    this.setState({
      rules: this.state.rules.concat([{
        column,
        relation,
        condition
      }])
    });
  }

  /**
   * Remove a rule, with an immutable state change.
   */
  onRemoveRule(index) {
    this.setState({
      rules: [
        ...this.state.rules.slice(0, index),
        ...this.state.rules.slice(index + 1)
      ]
    });
  }

  /**
   * Handle a change in a rule's column attribute.
   *
   * @param index
   * @param column
   */
  onRuleColumnChange(index, column) {
    const relation = this.getNextRelation(column, this.state.rules[index]);
    const condition = this.getNextCondition(column, relation, this.state.rules[index]);

    this.updateRule(index, {
      column,
      relation,
      condition
    })
  }

  /**
   * Handle a change in a rule's relation attribute.
   *
   * @param index
   * @param relation
   */
  onRuleRelationChange(index, relation) {
    const condition = this.getNextCondition(this.state.rules[index].column, relation, this.state.rules[index]);

    this.updateRule(index, {
      relation,
      condition
    });
  }

  /**
   * Handle a change in a rule's condition attribute.
   *
   * @param index
   * @param condition
   */
  onRuleConditionChange(index, condition) {
    this.updateRule(index, {
      condition
    });
  }

  /**
   * Given the column we're changing to and the current rule, return the next
   * relation value.
   *
   * @param nextColumn
   * @param currentRule
   */
  getNextRelation(nextColumn, currentRule) {
    // If the new column provides for the same relation, keep it.
    if(currentRule && (this.props.columns[nextColumn].relations[currentRule.relation] !== undefined)) {
      return currentRule.relation;
    }
    // Otherwise, return the first relation for the new column.
    return Object.keys(this.props.columns[nextColumn].relations)[0];
  }

  /**
   * Given the column and relation we're changing to and the current condition,
   * return the value that the condition should be changed to.
   *
   * @param nextColumn
   * @param nextRelation
   * @param currentRule
   */
  getNextCondition(nextColumn, nextRelation, currentRule) {
    // If the new relation provides for the same condition type, keep it.
    if(currentRule) {
      const currentConditionType = this.props.columns[currentRule.column].relations[currentRule.relation].type;
      const nextConditionType = this.props.columns[nextColumn].relations[nextRelation].type;

      if(currentConditionType === nextConditionType) {
        return currentRule.condition;
      }
    }

    // Otherwise, reset the condition to an empty string.
    return '';
  }

  /**
   * Handle the updating of a rule in our array in an immutable manner.
   *
   * @param index
   * @param updates
   */
  updateRule(index, updates) {
    this.setState({
      rules: [
        ...this.state.rules.slice(0, index),
        Object.assign({}, this.state.rules[index], updates),
        ...this.state.rules.slice(index + 1)
      ]
    });
  }

  /**
   * Render the Rules Editor.
   */
  render() {
    const { name } = this.props;
    const { rules } = this.state;

    const ruleElements = rules.map((rule, i) => {
      return <RulesEditorRule
        key={i}
        rule={rule}
        columns={this.props.columns}
        onRemove={this.onRemoveRule.bind(this, i)}
        onColumnChange={this.onRuleColumnChange.bind(this, i)}
        onRelationChange={this.onRuleRelationChange.bind(this, i)}
        onConditionChange={this.onRuleConditionChange.bind(this, i)}
      />
    });

    const rulesJSON = JSON.stringify(this.state.rules);

    return(
      <div>
        {ruleElements}
        <button type="button" className="btn btn-default" onClick={this.onAddRule.bind(this)}>
          Add condition
        </button>
        <input type="hidden" name={name} value={rulesJSON} />
      </div>
    );
  }

}

const RulesEditorRule = ({ rule, columns, onRemove, onColumnChange, onRelationChange, onConditionChange }) => {
  const { column, relation, condition } = rule;

  const currentColumn = columns[column];
  const currentRelation = currentColumn.relations[relation];

  let conditionEditor = null;
  switch(currentRelation.type) {
    case 'text':
      conditionEditor = <RulesEditorConditionInputText condition={condition} onChange={onConditionChange} />;
  }

  return (
    <div className="row">
      <div className="col-md-6">
        <RulesEditorColumnSelect currentColumnName={column} columns={columns} onChange={onColumnChange} />
      </div>
      <div className="col-md-6">
        <RulesEditorRelationSelect currentRelationName={relation} relations={currentColumn.relations} onChange={onRelationChange} />
      </div>
      <div className="col-md-6">
        {conditionEditor}
      </div>
      <div className="col-md-6">
        <button type="button" class="btn btn-link btn-sm" onClick={onRemove}>Remove</button>
      </div>
    </div>
  );

};

const RulesEditorColumnSelect = ({ currentColumnName, columns, onChange }) => {
  const options = Object.keys(columns).map((columnName) => {
    return { label: columns[columnName].label, value: columnName }
  });

  return <InputSelect options={options} value={currentColumnName} onChange={onChange} />;
};

const RulesEditorRelationSelect = ({ currentRelationName, relations, onChange }) => {
  const options = Object.keys(relations).map((relationName) => {
    return { label: relations[relationName].label, value: relationName }
  });

  return <InputSelect options={options} value={currentRelationName} onChange={onChange} />;
};

const RulesEditorConditionInputText = ({ condition, onChange }) => {

  const handleChange = (e) => {
    onChange && onChange(e.target.value);
  };

  return (
    <input type="text" value={condition} onChange={handleChange} />
  );

};
